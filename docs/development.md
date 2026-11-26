# Development guide

## Environment

This repository contains a Garry's Mod addon, not a standalone Lua application. Stock Lua cannot parse all GLua syntax and cannot emulate Garry's Mod globals, realms, hooks, net messages, or VGUI.

A realistic development environment needs:

- a Garry's Mod dedicated server;
- the addon mounted below `garrysmod/addons/gmod-integration`;
- valid test credentials for connected flows;
- the mandatory `gwsockets` server module for all connected flows;
- test clients for client UI and net flows;
- optional addons only for the integration being exercised.

Never use production credentials for malformed-input, RCON, Lua runner, ban, kick, or rank synchronization tests.

Install the GWSockets binary matching the dedicated server's operating system and process architecture in `garrysmod/lua/bin/`, then fully stop and start the server. A map change or player reconnection does not load a newly installed native module. Missing-module regression tests intentionally omit it: expect explicit administrator guidance, available local configuration and rejected connected operations, with no HTTP fallback.

## Adding or changing a file

Use the realm prefix expected by the bootstrap:

- `sv_name.lua` for server-only behavior;
- `cl_name.lua` for client-only behavior;
- `sh_name.lua` for code safe in both realms.

The loader recursively discovers files, so no registry update is normally required. Shared files must guard realm-specific blocks with `if SERVER` or `if CLIENT`.

## Request façade changes

1. Use `gmInte.api`; connected operations travel only through the authenticated server WebSocket.
2. Preserve local endpoint placeholders and JSON-safe tables, and update the shared backend allowlist/schema.
3. Provide success and failure callbacks when behavior depends on delivery; success waits for a correlated acknowledgement.
4. Never log credentials, report contents or image data. Player tools never receive platform tokens.
5. Use `postLog` only for batchable telemetry. The bounded FIFO handles unsent work; never automatically replay uncertain mutations.
6. Test protocol readiness, rejection, timeout, disconnect, queue saturation, credential rotation and reconnect.
7. For player tools, keep the explicit relay kinds, rebuild identity server-side, and enforce chunk, memory, depth, rate and expiry limits.

## WebSocket changes

Inbound WebSocket data is privileged remote input. A handler must:

- validate that `data` is a table;
- validate every required field and constrain strings/numbers;
- reject unexpected commands or rank/config values;
- avoid dynamically selecting arbitrary functions;
- log actor and action without logging credentials or unnecessarily sensitive payloads;
- preserve callback cleanup and reconnect behavior.

RCON and Lua execution require explicit staging tests and careful review. Never add another execution path as a convenience helper.

## Net message changes

Register the ID in the correct `netReceive` table. For client-to-server messages, validate and rate-limit on the server even if the UI already constrains input. Assume a custom client can send any ID and JSON payload repeatedly.

Check at least:

- malformed or non-table JSON;
- missing and wrong-typed fields;
- excessive string/table size;
- unauthorized players;
- repeated requests;
- disconnects during asynchronous callbacks.

## Configuration changes

Add a default in `sv_default_config.lua`, expose only the intended subset through `publicGetConfig`, and update admin UI/console behavior where applicable. Never send `gmInte.config.token` in public config. If a key or data path changes, retain a migration path and document removal criteria for the legacy form.

Administrative snapshots use `getConfigSnapshot`, an allowlist of recognized settings without the token.
Keep the token control write-only and use `tokenConfigured` for its saved state. Never print the persisted
configuration table directly. Connection tests must project their response and revalidate the recipient's
permission after asynchronous work. A client-provided rank or identity is never an authorization input.

The administrative panel refreshes Premium entitlement from server metadata when opening. Preserve
the distinction between a confirmed free server (`premium = false`) and unknown entitlement; only the
former shows the purchase action. The install-GWSockets action is shown only for a confirmed missing
module (`websocket = false`), even when a loaded module's connection is currently offline. Verify that
late metadata replies cannot reopen a panel for a revoked administrator or cross a credential change.

## Translations

English is the fallback table. New user-facing text should use a stable namespaced key and provide an English fallback at the call site. Update `sh_en.lua` first, then keep all language tables aligned. Placeholder forms such as `{1}` and `{2}` must remain consistent between languages.

Useful parity check:

```bash
for file in lua/gmod_integration/languages/sh_*.lua; do
  printf '%s: ' "$file"
  rg -c '^\s*\["' "$file"
done
```

## Optional addon integrations

Keep third-party code inside a narrowly named module directory. Guard its global before use, follow the upstream hook signature, normalize SteamID/SteamID64 deliberately, and prevent synchronization loops with a scoped cache when both systems emit change events.

Test both with and without the dependency installed.

## Client tools

`gmi_tools screenshot [title]`, `gmi_tools bug` and `gmi_tools settings` open the existing client tools.
The command completes these action names in the game console, without suggesting credentials or
changing authorization. The existing screenshot, report and administration aliases remain available.

Screenshot commands queue one capture and explain when the console or a game menu must be closed.
Rendering waits until the console, Escape menu and context menu have been clear for half a second,
then checks them again immediately before capture. Repeated requests cannot overwrite a queued title.
The settings action uses the existing client and server permission checks.

## Validation checklist

Static checks available today:

```bash
git status --short
git diff --check
git diff --stat
git diff
rg -n 'changedSymbol|changedEvent|changedKey' lua
```

Run the repository-owned mocked regressions first:

```bash
python3 scripts/test_lua.py
```

The runner uses a Lua 5.3/5.4 executable or shared library and translates GLua operators only in memory.
It preserves source files and tests the transport, relay and net boundaries with engine mocks; it does
not emulate a Garry's Mod dedicated server. There is no configured GLua linter. The staging smoke test is:

1. start the dedicated server and confirm every file loads without Lua errors;
2. connect an ordinary player and an admin;
3. verify public config, player-ready and admin permissions; confirm neither the public nor admin reply contains the saved server token, and the token field opens empty with its configured-state placeholder;
4. exercise the changed feature in success and failure modes;
5. disconnect/reconnect WebSocket, rotate credentials, and verify no automatic replay of uncertain writes;
6. inspect server and client consoles for duplicate hooks, leaked payloads, and retries;
7. restart or change map to verify persistence and clean reinitialization.

Report exactly which checks ran. A static diff review is not a runtime test.

For an end-to-end acceptance session, use a dedicated test server, test Discord channels, one
ordinary player and one administrator. Record the backend revision and addon commit actually running,
then record each result separately; a configured destination or an online socket is only a prerequisite.

| Flow | Required observation |
| --- | --- |
| Chat in both directions | One synthetic message arrives once in the configured game/Discord destination, with no echo loop. Check disabled directions and filtering separately. |
| Screenshot | The player receives the storage outcome, the image opens in the panel, and configured Discord publication is independently confirmed. A Discord failure must preserve the stored image and show a partial-delivery notice. |
| Bug report | A report without an attachment and one with a valid capture each appear once. A failed or oversized capture preserves the report, closes the accepted form and explains the attachment failure. Do not resend an accepted report. |
| Account verification and roles | Link a test account, verify the configured role/rank result, then confirm an ordinary player cannot use administrator settings or issue connection tests. Never use a production account for rank changes. |
| Rewards | Use synthetic rules for verification, votes and a playtime threshold. Observe each enabled economy's credit once, its private notification and the dashboard acknowledgement. Add a server Lua action that checks the bound `ply`, `steamID64` and `reward` variables, then observe its effect once. Check syntax rejection and a runtime failure after a partial effect; source and raw exception details must not appear in player output or module logs. Disconnect the recipient before a response and verify deferred delivery on return. Remove each optional integration and confirm it stays pending. Drop an acknowledgement, reconnect, then restart/change map and confirm that the local SQLite journal prevents another execution. Simulate an interrupted `started` action and verify `uncertain` without replay. Check real Pointshop wallet loading and every economy provider's asynchronous persistence separately; mocked tests do not confirm provider durability or deferred Lua work. |
| Whitelist mode | Confirm manual and Discord-role grants allow a fresh join. Remove the role while the test player is online: only a confirmed fresh denial should remove the player, preserving manual/in-game-admin/Discord-admin exemptions. Simulate an access-provider failure: new ordinary joins fail closed, existing players stay connected and are checked again after recovery. Check role/config notifications, a missed notification recovered by the 30-second sweep, and late replies after a reconnect. Disable whitelist mode remotely while disconnected, then reconnect: current configuration must apply before any online denial can kick. |
| Disconnect and reconnect | Interrupt only the test connection, restore it, and wait for protocol readiness. Confirm future requests work and an already-sent uncertain mutation is not automatically replayed. |
| Map change and restart | In an agreed interruption window, change map and restart the dedicated server separately. Verify saved settings, one connection and one copy of each hook/relay afterward. |
| Missing GWSockets | On a separate stopped test installation, omit the binary and start it. Administrators must see dependency guidance; connected operations fail explicitly and local configuration remains usable. |
| Administrative panel actions | With GWSockets loaded, verify the installation action is absent even if the connection is offline. Confirm the purchase action is absent for a Premium server, visible for a confirmed free server, and absent when entitlement cannot be loaded. Reopen after a Premium change and verify the current entitlement. |
| Live console | Open the server Console page with an authorized account and print synthetic output through Lua `print`, `Msg`, `MsgN` and `MsgC`. Confirm one plain-text copy arrives while local output is preserved. Close the final viewer and confirm both runtime exporter flags become false; repeat with two viewers so closing one retains the other subscription. Interrupt the gateway and confirm the exporter stops within 30 seconds, then reconnect without replaying old output. Enable a stream, change another setting, inspect the private config file and restart: the persisted exporter flag and runtime default must both be false. Exercise bursts, long/cyclic values and debug mode without recursive traffic. Native engine/binary output is outside these Lua hooks and must not be claimed as captured. |
| Dashboard and Discord RCON | With an authorized panel administrator and an empty game server, confirm a synthetic dashboard command uses `wsPanelRcon` and succeeds without any Steam link or in-game player. Confirm a panel account without administration rights cannot dispatch it. Separately use Discord `wsAuthorizedRcon`: an absent or demoted linked player must still be denied, and a current configured administrator accepted. Retry identical packets and then reuse an ID across methods or actors; observe one console submission at most. Check stale deadlines, malformed identities, extra fields, commands beyond 8,192 UTF-8 bytes and a simulated console exception. A success acknowledgement confirms console submission rather than native command output or eventual effects; command text must not appear in addon diagnostics. |

Record blocked or unobserved cases as pending, including those requiring a connected player or an
agreed interruption. Keep account identifiers, report text, captures and diagnostics private.

## Release notes

The release workflow owns `gmInte.version` and packaging. Markdown under `docs/` and `AGENTS.md` is excluded from Workshop packaging by `addon.json`, while remaining available in the source repository.

Pull requests and branch pushes run the mocked Lua and release-workflow regressions. The release
workflow runs the same checks before its version job, so a failed test cannot bump the version, create a tag or publish an
archive or Workshop update. The monorepo also tests its pinned addon commit before image publication.
These automated gates do not replace the dedicated-server acceptance session above.

Run `python3 scripts/test_release.py` to check version resolution and recovery against temporary local
Git repositories. These tests execute the workflow's shell steps without publishing releases.

The version job is intentionally idempotent. On a rerun it reuses its release commit, repairs a missing
branch push or tag, and does not increment the version again. Push-triggered runs also recover legacy
release commits by their `chore: bump version to X.Y.Z` subject. Keep this subject and the
`Release-Source` and `Release-Run` commit trailers intact. Do not move or recreate an existing release
tag on another commit.

Each new manual dispatch honors its requested `version_type`, including `major` when the current
commit already has a patch release. Rerunning that dispatch reuses only the release marked with its
own GitHub run ID. A fresh dispatch fails if its source branch has advanced; dispatch again from the
latest commit after the preceding release finishes.

For the WebSocket-only v6 rollout, merge the transport branch first and wait for its automatic patch
release to finish. Then run **Auto Release** on **main** with **version_type: major** to create
`6.0.0` from the latest 5.x release. After publication succeeds, update the monorepo's addon submodule
to the published `v6.0.0` commit. The release workflow writes `gmInte.version`; do not bump it manually.
