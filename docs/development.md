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
| Whitelist mode | Confirm manual and Discord-role grants allow a fresh join. Remove the role while the test player is online: only a confirmed fresh denial should remove the player, preserving manual/in-game-admin/Discord-admin exemptions. Simulate an access-provider failure: new ordinary joins fail closed, existing players stay connected and are checked again after recovery. Check role/config notifications, a missed notification recovered by the 30-second sweep, and late replies after a reconnect. Disable whitelist mode remotely while disconnected, then reconnect: current configuration must apply before any online denial can kick. |
| Disconnect and reconnect | Interrupt only the test connection, restore it, and wait for protocol readiness. Confirm future requests work and an already-sent uncertain mutation is not automatically replayed. |
| Map change and restart | In an agreed interruption window, change map and restart the dedicated server separately. Verify saved settings, one connection and one copy of each hook/relay afterward. |
| Missing GWSockets | On a separate stopped test installation, omit the binary and start it. Administrators must see dependency guidance; connected operations fail explicitly and local configuration remains usable. |

Record blocked or unobserved cases as pending, including those requiring a connected player or an
agreed interruption. Keep account identifiers, report text, captures and diagnostics private.

## Release notes

The release workflow owns `gmInte.version` and packaging. Markdown under `docs/` and `AGENTS.md` is excluded from Workshop packaging by `addon.json`, while remaining available in the source repository.

Pull requests and branch pushes run the mocked Lua regressions. The release workflow runs the same
checks before its version job, so a failed test cannot bump the version, create a tag or publish an
archive or Workshop update. The monorepo also tests its pinned addon commit before image publication.
These automated gates do not replace the dedicated-server acceptance session above.

The version job is intentionally idempotent. On a rerun it reuses a release tag/commit associated with the triggering commit, accepts a target version already written in a clean worktree, repairs a missing branch push or missing tag, and does not increment the version again. Release commits should retain the `chore: bump version to X.Y.Z` subject because recovery of releases created by the legacy workflow uses it when available. Do not move or recreate an existing release tag on another commit.
