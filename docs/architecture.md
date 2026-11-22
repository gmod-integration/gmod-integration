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
- Access controls: branch, linked-account, ban, Discord-ban, whitelist, and maintenance filters.
- Client tools: screenshots, bug reports, and Lua error reports.
- Remote administration: console commands and server Lua execution.
- Economy integrations: DarkRP, CH ATM, and GlorifiedBanking event trackers.

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

The façade retains local endpoint names and resolves `:serverID` (and client-side `:steamID64`). These
are dispatch keys, not HTTP calls. Only `addon.ready` protocol 1 confirms the connection; TCP open is
insufficient. At most four requests are in flight and 128 requests / 24 MiB are buffered. Requests
expire, and already-sent mutations are never replayed after a lost acknowledgement. Reconnects use
exponential backoff independently of any HTTP response. A credential change discards old queued work.

### Remote service to server

```text
WebSocket JSON -> explicit method allowlist + field validation -> existing handler
```

RCON, Lua execution, settings and moderation remain privileged operations. The dispatcher does not
look up arbitrary names on `gmInte`. Unknown or malformed commands are rejected before execution.

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

Defaults originate in `sv_default_config.lua`. Runtime values are persisted under `data/gm_integration/config.json`, can be edited by configured admin ranks, and synchronize with the remote service. Public client config is a deliberate subset; the server token remains server/admin-only and never travels in ordinary player tool requests.
`apiFQDN` remains persisted for compatibility with old configuration files but is no longer used or
shown as an active connection setting. Config saves and reconnect synchronization are serialized;
stale replies cannot replace newer local edits.

## External dependencies and compatibility

- Garry's Mod dedicated server APIs and GLua are required.
- `gwsockets` is required for all connected features. Missing modules fail visibly; local loading does not add an HTTP fallback.
- A compatible hosted WebSocket gateway must be deployed before this addon is distributed. Older gateways cannot confirm the new protocol.
- CAMI and many admin systems are supported opportunistically by the usergroup module.
- DarkRP, CH ATM, GlorifiedBanking, and AWarn3 integrations depend on their respective hooks/globals.

Optional integrations must fail closed or become inert when absent. They must not prevent the rest of the addon from loading.

## Persistence and generated state

- `data/gm_integration/config.json`: credentials and settings.
- `data/gm_integration/player_before_map_change.json`: adjusted-time restoration data.
- `data/gmod_integration/player_before_map_change.json`: legacy path still read for migration compatibility.
- Client report screenshots are temporarily written below `data/gmod_integration/report_bug/`.

None of these runtime data files belongs in the repository.

## Release path

The GitHub workflow calculates a semantic version, edits `gmInte.version`, creates a tag, builds release archives, creates a GitHub release, publishes Workshop content, and conditionally publishes marketplace updates. Normal feature commits must not bump the version manually.
