# Architecture

## Purpose and boundaries

The addon is the in-server half of Gmod Integration. It observes Garry's Mod events, sends state and logs to the HTTP API, receives privileged commands through a WebSocket, and provides client UI for configuration, verification, screenshots, and reports.

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

- `core/api/sh_http.lua`: API URL construction, bearer authentication, JSON requests, and three-second log batching.
- `core/api/sv_websocket.lua`: authenticated WebSocket lifecycle, inbound method dispatch, outbound request callbacks, and reconnect loop.
- `core/config/`: defaults, persisted settings, web synchronization, console commands, and admin UI.
- `core/net/`: one multiplexed `gmIntegration` net channel with realm-specific message allowlists.
- `core/security/sv_tokens.lua`: fetches a public server token and derives per-player temporary client tokens.
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

### Server to API

```text
GMod hook/module -> gmInte.http.get/post/put/delete
                 -> JSON + server bearer token
                 -> /v3 endpoint

High-volume event -> gmInte.http.postLog
                  -> in-memory batch (3 seconds or 30 entries)
                  -> /v3/servers/:serverID/logs
```

API helpers replace `:serverID` from server config. Client-side requests also replace `:steamID64` with `LocalPlayer():SteamID64()`.

### Remote service to server

```text
WebSocket JSON -> onMessage -> method lookup on gmInte -> handler
                                                |-> RCON / Lua
                                                |-> config change
                                                |-> ban / kick / rank / name
                                                `-> chat relay
```

This is the most privileged trust boundary in the addon. The current dispatcher is global-name based;

### Client/server net channel

```text
Client gmInte.SendNet -> "gmIntegration" -> server netReceive allowlist
Server gmInte.SendNet -> "gmIntegration" -> client netReceive allowlist
```

The payload is encoded as a JSON string after a string message ID. Message handlers—not the transport—own authorization and schema validation.

### Configuration

Defaults originate in `sv_default_config.lua`. Runtime values are persisted under `data/gm_integration/config.json`, can be edited by configured admin ranks, and synchronize with the remote service. Public client config is a deliberate subset; the server token must remain server/admin-only.

## External dependencies and compatibility

- Garry's Mod dedicated server APIs and GLua are required.
- `gwsockets` is required for WebSocket features; HTTP-only behavior can still load without it.
- The hosted Gmod Integration API/WebSocket service is required for connected features.
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
