# Architecture

## Purpose and boundaries

The addon is the in-server half of Gmod Integration. It observes Garry's Mod events, sends state and logs through the dedicated server's authenticated WebSocket, receives validated privileged commands on that socket, and provides client UI for configuration, verification, screenshots, and reports.

The remote API, Discord bot/web application, `gwsockets` binary module, and third-party admin/economy addons are external systems. Their implementation is outside this repository.

## Bootstrap and load order

Garry's Mod starts [lua/autorun/gmod_integration.lua](../lua/autorun/gmod_integration.lua). The bootstrap:

1. exits in single-player;
2. initializes `gmInte`, the version, and config defaults;
3. loads or migrates `data/gm_integration/config.json`;
4. loads languages, shared utilities, UI, the rest of `core/`, all `modules/`, then any remaining files;
5. deduplicates paths so the overlapping recursive passes do not include a file twice.

Realm behavior is filename-driven:

| Prefix | Server | Client |
| --- | --- | --- |
| `sv_` | included | ignored |
| `cl_` | sent with `AddCSLuaFile` | included |
| `sh_` | included and sent | included |

Renaming a file can therefore alter runtime behavior even when its contents do not change.

## Components

### Core

- `core/api/sh_api.lua`: local request façade, placeholder resolution and three-second log batching; no HTTP fallback.
- `core/api/cl_relay.lua` and `sv_relay.lua`: bounded, identity-checked player-tool transfers through the dedicated server.
- `core/api/sv_websocket.lua`: authenticated protocol readiness, allowlisted command dispatch, correlated request callbacks, bounded FIFO and reconnect backoff.
- `core/config/`: defaults, persisted settings, web synchronization, console commands, and admin UI.
- `core/net/`: one multiplexed `gmIntegration` net channel with realm-specific message allowlists.
- `core/net/sh_json.lua`: bounded JSON decoding shared by the net receivers and upload relay. Player API token issuance is removed.
- `core/utils/`: formats players/entities, tracks adjusted time and custom values, supplies player metatable helpers, and checks releases.
- `core/ui/`: fonts and colors.

### Modules

- Server lifecycle and player telemetry: `server_status`, `players_logs`, `console_live_exporter`.
- Discord/server synchronization: chat, bans, kicks, names, usergroups, and AWarn3 warnings.
- Access controls: branch, linked-account, ban, Discord-ban and whitelist filters.
- Client tools: screenshots, bug reports, and Lua error reports.
- Remote administration: console commands and server Lua execution.
- Economy integrations: DarkRP, CH ATM, and GlorifiedBanking event trackers.
- Rewards: authenticated delivery polling, fixed DarkRP/Pointshop/Pointshop 2 credits, server Lua
  scripts and a local durable action journal. Discord roles and reward eligibility remain platform-side.

## Main data flows

### Platform requests

```text
Server hook/module -> gmInte.api.get/post/postLog
                   -> bounded unsent FIFO -> authenticated WebSocket
                   -> addon.request -> shared allowlisted backend model
                   <- addon.response with matching id/status/body

Player screenshot/report/error -> compressed chunks over Garry's Mod net
                               -> server validates and rebuilds player identity
                               -> same authenticated WebSocket
```

Screenshot acknowledgements separately confirm storage (`saved`) and Discord publication
(`discordDelivered`). The relay forwards only these booleans and fixed delivery reasons; images,
stored records and credentials stay server-side. A Discord failure keeps the saved capture and
shows an explicit player notice. Failed chat deliveries produce bounded administrator diagnostics.
Neither path automatically replays an uncertain Discord publication.

The façade retains local endpoint names and resolves `:serverID` (and client-side `:steamID64`). These
are dispatch keys, not HTTP calls. Only `addon.ready` protocol 1 confirms the connection; TCP open is
insufficient. At most four requests are in flight and 128 requests / 24 MiB are buffered. Requests
expire, and already-sent mutations are never replayed after a lost acknowledgement. Reconnects use
exponential backoff independently of any HTTP response. A credential change discards old queued work.
DNS hostnames use `wss`; plaintext `ws` is selected only for exact `localhost` or canonical private/loopback
IPv4 literals. A hostname resembling a private address does not disable TLS. These local plaintext
connections require a trusted network; the addon does not turn an internal address into an encrypted link.

### Remote service to server

```text
WebSocket JSON -> explicit method allowlist + field validation -> existing handler
```

RCON, Lua execution, settings and moderation remain privileged operations. The dispatcher does not
look up arbitrary names on `gmInte`. Unknown or malformed commands are rejected before execution.

The dashboard Console page leases Lua console output with the allowlisted `wsConsoleStream`
command: `{ method = "wsConsoleStream", enabled = true, expiresAt = <Unix milliseconds> }`.
An enabled command requires a ready authenticated socket and a future deadline no more than 35 seconds
away (including clock tolerance); the actual monotonic lease is capped at 30 seconds. Gateway renewals
keep an open authorized viewer active. Closing the final viewer sends `enabled = false, expiresAt = 0`.
`gmInte.config.consoleLiveExporter` and its `gmInte.enableConsoleLiveExporter` mirror are runtime flags;
they reset on boot, Lua auto-refresh, socket replacement/loss/error, credential changes, shutdown and
lease expiry. Local configuration saves always write the flag as `false`; it is excluded from ordinary
settings synchronization and cannot be enabled through `wsEditSetting`.

`console_live_exporter` preserves and wraps the server's Lua `print`, `Msg`, `MsgN` and `MsgC` functions.
It forwards plain text through the authenticated socket while a lease is active, strips MsgC color
arguments and does not traverse table contents. This covers Lua calls through those global functions,
not all native engine output, output written directly by binaries, or previously cached function
references. Native/local console output is preserved. Forwarded messages are limited to 32 KiB, the
queue to 64 messages/64 KiB, and transmission to 10 messages/64 KiB per second. Output beyond those
limits is truncated or dropped, never replayed after a close/disconnect. A forwarding guard prevents
transport diagnostics from recursively entering the stream; a failed send disables it silently.

Dashboard console requests use the separate `wsPanelRcon` method with exactly a UUID `requestID`,
`actorDiscordID` (one to twenty decimal digits), a nonblank single-line `command` of at most 8,192
bytes, and an `expiresAt` deadline in Unix milliseconds. The authenticated platform verifies the
actor's current panel administration rights before dispatch. The addon does not require a linked
Steam account, a connected player or an in-game administrator rank for this method, so an empty
game server remains manageable from the dashboard. This command is accepted only through the
ready authenticated WebSocket dispatcher; it is not a client-to-server net command.

Discord console requests retain `wsAuthorizedRcon` with a linked SteamID64. For that method, the
addon still resolves the online player and checks `gmIntIsAdmin()` immediately before submission,
using its configured administrator groups instead of historical platform stats. The panel method
does not relax the Discord command's existing player authorization.

Both methods reserve UUIDs before any effect, share a bounded 128-entry recent-request cache, and
bind each cached result to its method, actor, command and deadline. Reusing an ID with another
method or actor fails; identical duplicates do not execute twice while their deadline remains valid.
Both reject NUL, CR and LF; semicolon syntax retains normal console behavior. The backend normally
sets a five-second deadline. The addon rejects deadlines with at most one second remaining or more
than ten seconds ahead, accounting conservatively for `os.time()` second precision. Replies carry
`addon.command-result` and the exact originating method. Success confirms console acceptance, not
command output or the command's eventual effects. The legacy `wsRcon` method is rejected, and older
addons do not recognize `wsPanelRcon`. Keep host clocks aligned and deploy the matching addon/backend
before using this flow; missing acknowledgements remain uncertain. Actor diagnostics contain the
validated account ID, never the submitted command text.

### Client/server net channel

```text
Client gmInte.SendNet -> "gmIntegration" -> server netReceive allowlist
Server gmInte.SendNet -> "gmIntegration" -> client netReceive allowlist
```

The outer JSON is size/depth checked and parsed under `pcall`. Handlers own authorization and domain
validation. Player uploads use paced 30,000-byte chunks, one assembly per player, bounded encoded and
decoded sizes, a shared reservation budget, timeouts and disconnect cleanup. The only relayed client
operations are screenshots, bugs and errors; the server derives their actor and server identity.

### Configuration

Defaults originate in `sv_default_config.lua`. Runtime values are persisted under `data/gm_integration/config.json`, can be edited by configured admin ranks, and synchronize with the remote service. Public client config is a deliberate subset. The saved server token stays on the dedicated server: administrative snapshots and console config output expose only `tokenConfigured`, never the credential. The admin token control starts empty and accepts a replacement; opening, focusing or clearing that control does not change the saved token. Connection-test replies project only bounded server ID/name or a generic failure and recheck the current player's permission after the asynchronous request.
`apiFQDN` remains persisted for compatibility with old configuration files but is no longer used or
shown as an active connection setting. Config saves and reconnect synchronization are serialized;
stale replies cannot replace newer local edits.

Opening the administrative panel refreshes the server's Premium status through the existing
authenticated server-metadata request. Only its boolean entitlement is added to the administrative
snapshot; it is neither editable nor persisted as addon configuration. The buy-Premium action appears
only for a confirmed free server. Unknown metadata, an offline connection or a failed lookup does not
show an upgrade prompt, while local configuration remains available. The GWSockets installation action
depends on the server module being loaded, independently of whether its WebSocket is connected.
Metadata callbacks recheck the recipient's permission and discard superseded replies or replies from
an older server identity, credential or connection generation.

## External dependencies and compatibility

- Garry's Mod dedicated server APIs and GLua are required.
- `gwsockets` is required for all connected features. Missing modules fail visibly; local loading does not add an HTTP fallback.
- A compatible hosted WebSocket gateway must be deployed before this addon is distributed. Older gateways cannot confirm the new protocol.
- CAMI and many admin systems are supported opportunistically by the usergroup module.
- DarkRP, CH ATM, GlorifiedBanking, and AWarn3 integrations depend on their respective hooks/globals.

Optional integrations must fail closed or become inert when absent. They must not prevent the rest of the addon from loading.

## Required account verification

When `forcePlayerLink` is enabled, ready players stay blocked until a current account lookup confirms
their Discord link. Unverified players remain queued across the 30-second reminder sweeps. The kick
deadline starts with the first challenge and is not reset by refresh requests; a zero timeout keeps the
block without kicking. Enabling the option also checks existing ready players on the next sweep.
Disabling it releases the account-verification block and invalidates pending callbacks. Disconnects
remove queued work. A successful account check does not release a separate wrong-branch block.

## Whitelist mode

The persisted `maintenance` setting now appears as **Whitelist mode**. Manual whitelist access and the
configured Discord whitelist role grant the same admission permission; the role grant is evaluated
fresh and does not overwrite the manual setting. Configured in-game administrator groups retain
their existing exemption.

Every connection requests fresh access after `PlayerInitialSpawn` and a deferred tick, allowing spawn
hooks to assign the real in-game usergroup first. The `player_connect` event supplies no rank; unknown
groups and pre-spawn sessions receive no administrator exemption or early access decision. Refresh
commands and sweeps cannot skip this wait, and a disconnected session's deferred callback is discarded.
While whitelist mode is enabled the access check uses
`GET /servers/:serverID/players/STEAM_ID/access`, whose successful response must include boolean
`bypassMaintenance` and `discordAdmin` fields. With whitelist mode disabled, joins use the existing raw
player endpoint so ban checks do not depend on Discord availability. New joins fail closed during an
access-provider outage when whitelist mode is enabled, while local administrators retain their exemption.

The authenticated command `wsRefreshPlayerAccess` accepts only `method` and an optional 17-digit
`steamID`. Omission refreshes all connected players; the command supplies no access grant. Changes to
manual access, Discord roles or the configured role invalidate the current answer and request a fresh
one. Reconnects and whitelist/administrator configuration changes also invalidate pending answers.
After reconnect, online checks wait for current configuration synchronization; failed or incomplete
policy snapshots retry after 10 seconds. A reply from an earlier connection or before a newer remote
edit cannot replace that policy or permit kicks using an old local mode. Confirmed local configuration
uploads also release this wait.
A 30-second sweep recovers missed notifications, with at most two online access requests at once.
An explicit successful denial removes an online player only while whitelist mode is enabled and no
administrator or whitelist exemption applies. Provider failures and malformed responses retry after
10 seconds without expelling an already connected player. Per-connection identities and revision checks
discard late replies after reconnect, disconnect, configuration changes or a newer role notification.

## Persistence and generated state

### Reward delivery

The server-only rewards module polls `POST /servers/:serverID/rewards/poll` every thirty seconds and
after player joins or protocol readiness. It reports the three detected integrations and at most 64
online human Steam identities per request. Batches rotate on larger servers. Responses are limited to
ten deliveries with five actions each. Every delivery carries a grant UUID, acknowledgement token,
Steam identity, rule title, Unix-seconds expiry and immutable action UUIDs and contents. The whole
response is validated before any action runs. Fixed economy actions carry an amount; a `lua` action
carries the complete server script configured by an authorized dashboard administrator. Console
commands, remote function names and client execution fields are not accepted. Credentials, host,
socket and connection generation must still match when the reply arrives.

The fixed economy actions are `darkrp_money`, `pointshop_points` and `pointshop2_points`, each for an
integer between 1 and 1,000,000. Missing dependencies, uninitialized wallets or a player who left since
polling produce a `pending` acknowledgement without consuming the action. New joins get a ten-second
wallet initialization grace period. Integration availability is rechecked immediately before execution.
The fixed adapters use [DarkRP's player money API](https://github.com/FPtje/DarkRP/blob/master/gamemode/modules/money/sv_money.lua),
[Pointshop's player extension](https://github.com/adamdburton/pointshop/blob/master/lua/pointshop/sv_player_extension.lua)
and [Pointshop 2's documented standard points API](https://pointshop2.readthedocs.io/en/latest/api/index.html).

The `lua` action executes in the dedicated server realm with normal server Lua privileges. The
dashboard script is compiled with [CompileString](https://wiki.facepunch.com/gmod/Global.CompileString)
and `handleError = false`; compilation does not execute the chunk. The wrapper binds local values
`ply` (the online recipient), `steamID64`, and `reward = { id, actionID, name, steamID64 }` through
function arguments. No string placeholder substitution is performed, and script source is never
sent to player clients or included in module error logs. The payload must contain nonblank source,
no NUL bytes and at most 65,536 UTF-8 bytes; the backend additionally limits it to 16,384 characters.
A missing compiler or source-digest function stays `pending` with `lua_unavailable`. Syntax errors
are reported as `failed` / `lua_compile_failed` before the durable action reservation.

The GMod SQLite table `gm_integration_reward_actions` records an action as `started` before calling its
integration or running its compiled Lua chunk, then records the outcome. Its primary key includes
server, grant and action identity; the saved fingerprint binds the player, action type, amount or
[SHA-256 source digest](https://wiki.facepunch.com/gmod/util.SHA256), and expiry. A repeated delivery only
acknowledges the saved result. A leftover `started` action, an integration exception, or a failure to
save the final outcome becomes `uncertain` and is never executed again automatically. A script
exception or explicit `return false` records `lua_execution_failed`; partial effects cannot be ruled out.
The server
acknowledges results through `POST /servers/:serverID/rewards/ack`; losing that acknowledgement is
recovered by the next poll consulting the journal. Changing the platform token does not erase it.

Expired payloads cannot execute. Journal rows are retained through expiry plus one day, then pruned;
the journal stops accepting new credits at 100,000 rows. Storage failures fail closed. Back up GMod's
SQLite database with the server; deleting/restoring an older journal can remove duplicate protection.
`delivered` confirms that the integration accepted its call, not that an external economy database
has flushed it durably. The integrations control their own asynchronous persistence and must be
tested with the server's real providers. For Lua, success confirms that the synchronous chunk returned
without an error or `false`; it cannot confirm work scheduled for later by the script. Do not retry
an uncertain action before checking its effects.

Only a fully delivered game-action bundle generates a translated, private chat notification. The
acknowledgement token and server credentials never enter a player net payload or chat message.

- `data/gm_integration/config.json`: credentials and settings.
- `data/gm_integration/player_before_map_change.json`: adjusted-time restoration data.
- `data/gmod_integration/player_before_map_change.json`: legacy path still read for migration compatibility.
- Client report screenshots are temporarily written below `data/gmod_integration/report_bug/`.

None of these runtime data files belongs in the repository.

## Release path

The GitHub workflow calculates a semantic version, edits `gmInte.version`, creates a tag, builds release archives, creates a GitHub release, publishes Workshop content, and conditionally publishes marketplace updates. Normal feature commits must not bump the version manually.
