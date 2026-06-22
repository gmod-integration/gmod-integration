# Development guide

## Environment

This repository contains a Garry's Mod addon, not a standalone Lua application. Stock Lua cannot parse all GLua syntax and cannot emulate Garry's Mod globals, realms, hooks, net messages, or VGUI.

A realistic development environment needs:

- a Garry's Mod dedicated server;
- the addon mounted below `garrysmod/addons/gmod-integration`;
- valid test credentials for connected flows;
- `gwsockets` when testing WebSocket behavior;
- test clients for client UI and net flows;
- optional addons only for the integration being exercised.

Never use production credentials for malformed-input, RCON, Lua runner, ban, kick, or rank synchronization tests.

## Adding or changing a file

Use the realm prefix expected by the bootstrap:

- `sv_name.lua` for server-only behavior;
- `cl_name.lua` for client-only behavior;
- `sh_name.lua` for code safe in both realms.

The loader recursively discovers files, so no registry update is normally required. Shared files must guard realm-specific blocks with `if SERVER` or `if CLIENT`.

## HTTP changes

1. Use `gmInte.http` rather than calling `HTTP` directly.
2. Preserve endpoint placeholders and send JSON-safe tables.
3. Provide success and failure callbacks when behavior depends on delivery.
4. Avoid secrets or raw image data in debug logs.
5. Decide explicitly whether an event is immediate (`post`) or batchable telemetry (`postLog`).
6. Test success, non-2xx JSON, non-JSON, timeout/DNS failure, and missing credentials.

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

## Validation checklist

Static checks available today:

```bash
git status --short
git diff --check
git diff --stat
git diff
rg -n 'changedSymbol|changedEvent|changedKey' lua
```

There is no repository-owned test suite or configured GLua linter as of 2026-06-22. The minimum staging smoke test is:

1. start the dedicated server and confirm every file loads without Lua errors;
2. connect an ordinary player and an admin;
3. verify public config, player-ready, token, and admin permissions;
4. exercise the changed feature in success and failure modes;
5. disconnect/reconnect the API or WebSocket if the change touches transport;
6. inspect server and client consoles for duplicate hooks, leaked payloads, and retries;
7. restart or change map to verify persistence and clean reinitialization.

Report exactly which checks ran. A static diff review is not a runtime test.

## Release notes

The release workflow owns `gmInte.version` and packaging. Markdown under `docs/` and `AGENTS.md` is excluded from Workshop packaging by `addon.json`, while remaining available in the source repository.

The version job is intentionally idempotent. On a rerun it reuses a release tag/commit associated with the triggering commit, repairs a missing branch push or missing tag, and does not increment the version again. Release commits must retain the `chore: bump version to X.Y.Z` subject because recovery of releases created by the legacy workflow relies on it. Do not move or recreate an existing release tag on another commit.
