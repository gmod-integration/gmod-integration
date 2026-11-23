-- Integrate the actual server receiver, permission method and configuration handlers.
-- All credentials and players below are synthetic; no Garry's Mod service is contacted.
local passes, failures = 0, {}
local playerMeta, players, commands, requests, sent, writes, logs, console, printedTables
local receiver, strings, position, now, encodedValues, hooks
local credential = "fixture-server-credential-keep-private"

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

local function encode(value)
    if type(value) == "string" then
        return '"' .. value:gsub('\\', '\\\\'):gsub('"', '\\"'):gsub('\n', '\\n') .. '"'
    end
    if type(value) ~= "table" then return tostring(value) end
    local entries = {}
    for key, child in pairs(value) do entries[#entries + 1] = encode(tostring(key)) .. ":" .. encode(child) end
    table.sort(entries)
    return "{" .. table.concat(entries, ",") .. "}"
end

local function player(group)
    return setmetatable({ valid = true, group = group }, { __index = playerMeta })
end

local function reset()
    SERVER, CLIENT = true, false
    players, commands, requests, sent, writes, logs, console, printedTables = {}, {}, {}, {}, {}, {}, {}, {}
    strings, position, now, encodedValues, hooks = {}, 0, 100, {}, {}
    isstring = function(value) return type(value) == "string" end
    istable = function(value) return type(value) == "table" end
    isnumber = function(value) return type(value) == "number" end
    isbool = function(value) return type(value) == "boolean" end
    isfunction = function(value) return type(value) == "function" end
    Color = function(r, g, b) return { r = r, g = g, b = b, a = 255 } end
    IsValid = function(value) return value and value.valid == true end
    CurTime = function() return now end
    SysTime = function() return now end
    FindMetaTable = function() return playerMeta end
    playerMeta = {
        IsPlayer = function() return true end,
        GetUserGroup = function(self) return self.group end,
        Nick = function() return "Synthetic player" end,
    }
    util = {
        AddNetworkString = function() end,
        TableToJSON = function(value)
            local json = encode(value)
            encodedValues[json] = copy(value)
            return json
        end,
        JSONToTable = function(json) return copy(assert(encodedValues[json], "Unexpected JSON fixture")) end,
    }
    net = {
        Receive = function(_, callback) receiver = callback end,
        ReadString = function() position = position + 1; return strings[position] end,
        Start = function() strings.out = {} end,
        WriteString = function(value) strings.out[#strings.out + 1] = value end,
        Send = function(ply) sent[#sent + 1] = { id = strings.out[1], data = util.JSONToTable(strings.out[2]), ply = ply } end,
        Broadcast = function() error("Configuration must never broadcast an unprojected payload") end,
    }
    hook = {
        Add = function(event, id, callback)
            hooks[event] = hooks[event] or {}
            hooks[event][id] = callback
        end,
        Run = function() end,
    }
    timer = { Simple = function(_, callback) callback() end, Create = function() end }
    file = { Write = function(path, contents) writes[#writes + 1] = { path = path, contents = contents } end }
    _G.player = { GetAll = function() return players end }
    game = { GetMap = function() return "test_map" end }
    concommand = { Add = function(name, callback) commands[name] = callback end }
    RunConsoleCommand = function() error("Unexpected console side effect") end
    PrintTable = function(value) printedTables[#printedTables + 1] = copy(value) end
    print = function(...)
        local values = {}
        for _, value in ipairs({ ... }) do values[#values + 1] = tostring(value) end
        console[#console + 1] = table.concat(values, " ")
    end
    GWSockets = { createWebSocket = function() end }
    gmInte = {
        config = {}, useDataConfig = true, version = "5.2.8", aprovedCredentials = true,
        api = {
            get = function(endpoint, success, failed) requests[#requests + 1] = { endpoint = endpoint, success = success, failed = failed } end,
            post = function(endpoint, body, success, failed) requests[#requests + 1] = { endpoint = endpoint, body = copy(body), success = success, failed = failed } end,
        },
        loadTranslations = function() end,
        getTranslation = function(_, fallback) return fallback end,
        hasWebsocketModule = function() return istable(GWSockets) and isfunction(GWSockets.createWebSocket) end,
        logWebsocketRequirement = function() return not gmInte.hasWebsocketModule() end,
        log = function(message) logs[#logs + 1] = message end,
        logWarning = function(message) logs[#logs + 1] = message end,
        logError = function(message) logs[#logs + 1] = message end,
    }
    loadGLua("lua/gmod_integration/core/config/sv_default_config.lua")
    gmInte.config.token = credential
    gmInte.config.id = "76561198000000001"
    gmInte.config.debug = true
    loadGLua("lua/gmod_integration/core/utils/sh_player_meta.lua")
    loadGLua("lua/gmod_integration/core/config/sv_settings.lua")
    loadGLua("lua/gmod_integration/core/net/sh_json.lua")
    loadGLua("lua/gmod_integration/core/net/sv_net.lua")
    loadGLua("lua/gmod_integration/core/config/sv_con.lua")
end

local function receive(id, body, ply)
    local json = util.TableToJSON(body or {})
    strings, position = { id, json }, 0
    now = now + 10
    receiver((#id + #json + 2) * 8, ply)
end

local function noCredential(value)
    assert(not encode(value):find(credential, 1, true), "A server credential crossed an output boundary")
end

local function test(name, callback)
    local ok, message = pcall(callback)
    if ok then passes = passes + 1
    else failures[#failures + 1] = name .. ": " .. tostring(message) end
end

test("ordinary players cannot read or replace credentials through any administrative net action", function()
    reset()
    local ordinary = player("user")
    for _, id in ipairs({ "getConfig", "saveConfig", "testConnection" }) do
        receive(id, { token = "attempted-replacement", adminRank = { user = true }, group = "superadmin", gmIntIsAdmin = true }, ordinary)
        receive(id, {}, ordinary)
    end
    assert(#sent == 0 and #requests == 0 and #writes == 0)
    assert(gmInte.config.token == credential and gmInte.config.adminRank.user == nil)
    noCredential(logs)
end)

test("all console aliases reject ordinary players before config reads or writes", function()
    reset()
    for _, name in ipairs({ "gmi", "gmod-integration" }) do
        commands[name](player("user"), name, { "config", "show" })
        commands[name](player("user"), name, { "config", "set", "token", "attempted-replacement" })
    end
    assert(#printedTables == 0 and #sent == 0 and #requests == 0 and #writes == 0)
    assert(gmInte.config.token == credential)
    noCredential(console)
end)

test("public and administrator snapshots expose configuration state without credentials or unknown records", function()
    reset()
    local admin, ordinary = player("superadmin"), player("user")
    gmInte.config.futureSecret = "fixture-unknown-private-record"
    gmInte.publicGetConfig(ordinary)
    receive("getConfig", {}, admin)
    assert(#sent == 1 and #requests == 1)
    requests[1].success(200, { id = gmInte.config.id, premium = true, token = credential, unknown = "private" })
    assert(#sent == 2 and sent[1].id == "publicConfig" and sent[1].ply == ordinary)
    assert(sent[1].data.config.token == nil and sent[1].data.config.futureSecret == nil)
    local snapshot = sent[2].data
    assert(sent[2].id == "adminConfig" and sent[2].ply == admin)
    assert(snapshot.token == nil and snapshot.futureSecret == nil and snapshot.tokenConfigured == true)
    assert(snapshot.id == gmInte.config.id and snapshot.websocket == true and snapshot.adminRank.superadmin == true)
    assert(snapshot.premium == true and snapshot.unknown == nil and gmInte.config.premium == nil)
    noCredential(sent)
    snapshot.adminRank.superadmin = false
    assert(gmInte.config.adminRank.superadmin == true)
    assert(gmInte.config.token == credential and gmInte.config.futureSecret == "fixture-unknown-private-record")
end)

test("administrator snapshots use fresh server metadata for both Premium and free servers", function()
    reset()
    local admin = player("superadmin")
    for index, premium in ipairs({ true, false }) do
        gmInte.config.premium = not premium
        receive("getConfig", { premium = not premium }, admin)
        assert(#requests == index and requests[index].endpoint == "/servers/:serverID")
        assert(#sent == index - 1)
        requests[index].success(200, { id = gmInte.config.id, premium = premium, token = credential })
        assert(#sent == index and sent[index].id == "adminConfig")
        assert(sent[index].data.premium == premium and sent[index].data.websocket == true)
        assert(gmInte.config.premium == not premium and #writes == 0)
    end
    noCredential(sent)
end)

test("malformed or mismatched Premium metadata remains unknown without hiding local settings", function()
    reset()
    local admin = player("superadmin")
    gmInte.config.premium = true
    for index, body in ipairs({
        false,
        {},
        { id = gmInte.config.id },
        { id = gmInte.config.id, premium = "false" },
        { id = gmInte.config.id, premium = 1 },
        { id = "different-server", premium = true },
    }) do
        receive("getConfig", {}, admin)
        requests[index].success(200, body)
        assert(#sent == index and sent[index].id == "adminConfig")
        assert(sent[index].data.id == gmInte.config.id and sent[index].data.premium == nil)
        assert(sent[index].data.tokenConfigured == true and sent[index].data.token == nil)
    end
    noCredential(sent)
end)

test("failed or unavailable metadata preserves local configuration and never assumes a free server", function()
    reset()
    local admin = player("superadmin")
    receive("getConfig", {}, admin)
    requests[1].failed(503, { error = credential, premium = false })
    assert(#sent == 1 and sent[1].data.premium == nil and sent[1].data.websocket == true)
    gmInte.aprovedCredentials = false
    receive("getConfig", {}, admin)
    assert(#requests == 1 and #sent == 2)
    assert(sent[2].data.premium == nil and sent[2].data.websocket == true)
    GWSockets = nil
    receive("getConfig", {}, admin)
    assert(#requests == 1 and #sent == 3)
    assert(sent[3].data.premium == nil and sent[3].data.websocket == false)
    noCredential(sent)
end)

test("administrator metadata callbacks recheck permission, player validity and configuration access", function()
    reset()
    local admin = player("superadmin")
    receive("getConfig", {}, admin)
    admin.group = "user"
    requests[1].success(200, { id = gmInte.config.id, premium = true })
    assert(#sent == 0)
    admin.group = "superadmin"
    receive("getConfig", {}, admin)
    admin.valid = false
    requests[2].failed(503, {})
    assert(#sent == 0)
    admin.valid = true
    receive("getConfig", {}, admin)
    gmInte.useDataConfig = false
    requests[3].success(200, { id = gmInte.config.id, premium = false })
    assert(#sent == 1 and sent[1].id == "notEditableConfig")
    noCredential(sent)
end)

test("a superseded metadata reply cannot override the most recent administrator snapshot", function()
    reset()
    local admin = player("superadmin")
    receive("getConfig", {}, admin)
    receive("getConfig", {}, admin)
    requests[1].success(200, { id = gmInte.config.id, premium = false })
    assert(#sent == 0)
    requests[2].success(200, { id = gmInte.config.id, premium = true })
    assert(#sent == 1 and sent[1].data.premium == true)
    requests[1].failed(503, {})
    requests[2].success(200, { id = gmInte.config.id, premium = false })
    assert(#sent == 1)
end)

test("stale metadata is discarded after a server, credential or connection generation change", function()
    for _, change in ipairs({ "id", "token", "generation" }) do
        reset()
        local admin = player("superadmin")
        local requestedID = gmInte.config.id
        receive("getConfig", {}, admin)
        if change == "generation" then
            hooks["GmodIntegration:Websocket:Restart"]["gmInte:WebSocket:InvalidateConfig"]()
        else
            gmInte.config[change] = "replacement-context"
        end
        requests[1].success(200, { id = requestedID, premium = true, token = credential })
        assert(#sent == 0 and #writes == 0)
        noCredential(logs)
    end
end)

test("console configuration display and snapshot construction never mutate or print the stored token", function()
    reset()
    commands.gmi(player("superadmin"), "gmi", { "config", "show" })
    assert(#printedTables == 1 and printedTables[1].token == nil and printedTables[1].tokenConfigured == true)
    noCredential(printedTables)
    noCredential(console)
    assert(gmInte.config.token == credential)
    gmInte.config.token = ""
    assert(gmInte.getConfigSnapshot().tokenConfigured == false and gmInte.getConfigSnapshot().token == nil)
end)

test("missing library warnings reach only administrators once while local configuration remains usable", function()
    reset()
    GWSockets = nil
    gmInte.aprovedCredentials = false
    local admin, ordinary = player("superadmin"), player("user")
    gmInte.publicGetConfig(ordinary)
    gmInte.publicGetConfig(admin)
    gmInte.publicGetConfig(admin)
    assert(#sent == 4 and sent[1].id == "publicConfig" and sent[1].ply == ordinary)
    assert(sent[3].id == "chatColorMessage" and sent[3].ply == admin)
    assert(sent[3].data[1].text:find("mandatory", 1, true))
    assert(sent[3].data[2].text:find("garrysmod/lua/bin", 1, true))
    assert(sent[3].data[2].text:find("fully stop and restart", 1, true))
    assert(gmInte.getConfigSnapshot().websocket == false)
    receive("getConfig", {}, admin)
    assert(sent[5].id == "adminConfig" and sent[5].data.websocket == false)
    assert(gmInte.saveSetting("debug", false) and #writes == 1 and #requests == 0)
    gmInte.tryConfig()
    assert(#requests == 0)
    commands.gmi(admin, "gmi", { "help" })
    assert(table.concat(console):find("Missing or failed to load (required)", 1, true))
    noCredential(console)
    noCredential(sent)
end)

test("connection diagnostics distinguish an unavailable library from invalid credentials", function()
    reset()
    local admin, ordinary = player("superadmin"), player("user")
    GWSockets = {}
    gmInte.testConnection(ordinary)
    gmInte.testConnection(admin)
    assert(#requests == 0 and #sent == 1)
    assert(sent[1].ply == admin and sent[1].data.error == "gwsockets_required")
    assert(gmInte.getConfigSnapshot().websocket == false)
    GWSockets.createWebSocket = function() end
    gmInte.testConnection(admin)
    assert(#requests == 1 and gmInte.getConfigSnapshot().websocket == true)
    noCredential(sent)
end)

test("an authorized replacement remains in server persistence and is not echoed to players or remote settings", function()
    reset()
    local admin, ordinary = player("superadmin"), player("user")
    players = { admin, ordinary }
    receive("saveConfig", { token = "replacement-server-credential" }, admin)
    assert(gmInte.config.token == "replacement-server-credential" and #writes == 1)
    assert(writes[1].path == "gm_integration/config.json")
    assert(writes[1].contents:find("replacement-server-credential", 1, true))
    for _, message in ipairs(sent) do
        assert(message.id == "publicConfig" and not encode(message.data):find("replacement-server-credential", 1, true))
    end
    assert(#requests == 1 and requests[1].endpoint == "/servers/:serverID")
    noCredential(logs)
end)

test("connection callbacks recheck the current server rank and never forward raw response credentials", function()
    reset()
    local admin = player("superadmin")
    receive("testConnection", {}, admin)
    assert(#requests == 1)
    admin.group = "user"
    requests[1].success(200, { id = gmInte.config.id, name = "Synthetic server", token = credential })
    assert(#sent == 0)
    admin.group = "superadmin"
    receive("testConnection", {}, admin)
    requests[2].success(200, { id = gmInte.config.id, name = "Synthetic server", token = credential, nested = { token = credential } })
    assert(#sent == 1 and sent[1].id == "testApiConnection")
    assert(sent[1].data.id == gmInte.config.id and sent[1].data.name == "Synthetic server")
    assert(sent[1].data.token == nil and sent[1].data.nested == nil)
    noCredential(sent)
    receive("testConnection", {}, admin)
    requests[3].failed(503, { error = credential, token = credential })
    assert(#sent == 2 and sent[2].data.error == "connection_failed")
    noCredential(sent)
end)

test("invalid or disconnected actors and oversized connection metadata fail without leaking payloads", function()
    reset()
    local admin = player("superadmin")
    receive("testConnection", {}, admin)
    admin.valid = false
    requests[1].success(200, { id = gmInte.config.id, name = "Synthetic server", token = credential })
    assert(#sent == 0)
    admin.valid = true
    receive("testConnection", {}, admin)
    requests[2].success(200, { id = string.rep("i", 1000), name = string.rep("n", 5000), token = credential })
    assert(#sent == 1 and sent[1].data.error == "connection_failed")
    noCredential(sent)
end)

if #failures > 0 then error(table.concat(failures, "\n")) end
io.write("Configuration security regressions: " .. passes .. " passed\n")
