# AGENTS.md

This file defines the working agreement for humans and coding agents changing this repository. It applies to the entire `gmod-integration` addon.

## Project summary

Gmod Integration is a Garry's Mod addon that connects a dedicated server and its players to the Gmod Integration HTTP API, WebSocket service, and Discord-facing features. It is written in Garry's Mod Lua (GLua), not stock Lua.

Start with:

- [Architecture](docs/architecture.md) for runtime and data-flow context.
- [Development guide](docs/development.md) for change and validation rules.

## Repository map

- `lua/autorun/gmod_integration.lua`: bootstrap, version, config loading, and recursive realm-aware loader.
- `lua/gmod_integration/core/`: HTTP, WebSocket, config, networking, security helpers, UI, and shared utilities.
- `lua/gmod_integration/modules/`: product features and third-party addon integrations.
- `lua/gmod_integration/languages/`: translation tables; English is the fallback.
- `materials/gmod_integration/`: shipped UI assets.
- `.github/workflows/auto-release.yml`: version bump, archives, GitHub release, Workshop, and marketplace publication.
- `addon.json`: Workshop packaging manifest. Markdown and CI files are intentionally excluded from the GMA.

## Non-negotiable rules

1. Preserve GLua syntax. Existing code uses `!`, `!=`, `&&`, `||`, `//`, `continue`, and Garry's Mod globals. Do not run a stock-Lua formatter that rewrites these constructs.
2. Respect realms. Name new files `sv_`, `cl_`, or `sh_`; the bootstrap uses these prefixes to decide whether to include or send a file. Never reference client-only globals from server execution or vice versa.
3. Treat `gmInte.config.token`, derived player tokens, HTTP authorization headers, screenshots, and bug reports as sensitive. Never print or expose them to ordinary clients.
4. Validate every client-to-server net payload on the server. Check type, size/range, permissions, player validity, and rate limits before side effects or HTTP requests.
5. Treat every WebSocket handler as remotely callable privileged input. Add explicit schema checks. RCON, Lua execution, rank changes, bans, kicks, and configuration writes are trust-critical operations.
6. Keep API endpoint placeholders intact: `:serverID` is resolved for all realms and `:steamID64` is resolved client-side by the HTTP helper.
7. Do not silently change persisted config keys or data paths. Add migrations when renaming either one.
8. Do not edit `gmInte.version` for normal changes. The release workflow owns version bumps.
9. Do not modify unrelated user changes. In particular, inspect `git status` before editing and preserve a dirty worktree.

## Coding conventions

- Use the existing global namespace, `gmInte`, only for public cross-file behavior. Prefer `local` for implementation details.
- Use descriptive, globally unique hook and timer IDs beginning with `gmInte:`.
- Keep HTTP access behind `gmInte.http`; use `postLog` only for batchable telemetry.
- Keep server-to-client and client-to-server message IDs in the respective allowlist tables in `core/net/`.
- Guard optional integrations (`sam`, `ULib`, `serverguard`, `DarkRP`, banking addons, AWarn3, and similar globals) before calling them.
- Keep English translation keys authoritative. Add the English fallback first and update every language file when translations are available. Never rename a key without updating all call sites.
- Follow the surrounding indentation and naming style. Do not perform broad style-only rewrites alongside behavior changes.
- Comments should explain trust assumptions, realm constraints, or non-obvious compatibility behavior—not restate the next line.

## Change workflow

Before editing:

1. Read the entry point and the files directly involved in the feature.
2. Inspect both directions of any HTTP, WebSocket, or net flow.
3. Check optional-addon behavior when the dependency is absent.
4. Check `git status --short` and preserve existing modifications.

After editing:

1. Run `git diff --check`.
2. Review `git diff --stat` and the complete diff.
3. Search for every changed function, event, config key, endpoint, and translation key with `rg`.
4. Validate realm boundaries and loader prefixes.
5. For network changes, test malformed, missing, oversized, unauthorized, and repeated input.
6. Run the relevant staging-server checks from [docs/development.md](docs/development.md).

There is currently no automated test suite or configured GLua linter. Do not claim runtime validation unless the addon was actually exercised on a Garry's Mod dedicated server.

## Definition of done

A change is complete when its normal path, failure path, permissions, realm behavior, optional dependencies, logs, and compatibility behavior have been considered; relevant documentation and translations are updated; static checks pass; and the remaining runtime validation is stated clearly.
