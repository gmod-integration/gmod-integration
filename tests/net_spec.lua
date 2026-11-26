-- Exercise the actual registered net receivers with a mocked engine JSON parser.
local receiver, strings, position, parsed, values, calls, logs, now
local passes, failures = 0, {}

local function reset(realm)
    SERVER, CLIENT = realm == "server", realm == "client"
    strings, position, parsed, values, calls, logs, now = {}, 0, 0, {}, {}, {}, 100
    isstring = function(value) return type(value) == "string" end
    istable = function(value) return type(value) == "table" end
    isnumber = function(value) return type(value) == "number" end
    IsValid = function(value) return value and value.valid == true end
    CurTime = function() return now end
    util = {
        AddNetworkString = function() end,
        JSONToTable = function(json)
            parsed = parsed + 1
            if values[json] ~= nil then return values[json] end
            error("Engine parser rejected malformed JSON")
        end,
    }
    net = {
        Receive = function(_, callback) receiver = callback end,
        ReadString = function() position = position + 1; return strings[position] end,
    }
    hook = { Add = function() end, Run = function() end }
    gmInte = {
        config = { debug = true },
        superadminGetConfig = function() calls.config = (calls.config or 0) + 1 end,
        superadminSetConfig = function() calls.save = (calls.save or 0) + 1 end,
        testConnection = function() calls.test = (calls.test or 0) + 1 end,
        receiveClientAPIChunk = function() calls.chunk = (calls.chunk or 0) + 1 end,
        receiveClientAPIResponse = function() calls.response = (calls.response or 0) + 1 end,
        log = function(text) logs[#logs + 1] = text end,
    }
    loadGLua("lua/gmod_integration/core/net/sh_json.lua")
    loadGLua("lua/gmod_integration/core/net/" .. (SERVER and "sv_net.lua" or "cl_net.lua"))
end

local function player(admin)
    return {
        valid = true,
        IsPlayer = function() return true end,
        gmIntIsAdmin = function() return admin == true end,
        Nick = function() return "Test player" end,
    }
end

local function receive(id, json, ply, bits)
    strings, position = { id, json }, 0
    return receiver(bits or (#json + #id + 2) * 8, ply or player())
end

local function test(name, callback)
    local ok, error = pcall(callback)
    if ok then passes = passes + 1
    else failures[#failures + 1] = name .. ": " .. tostring(error) end
end

test("server receiver ignores malformed, missing and scalar JSON without raising", function()
    reset("server")
    receive("getConfig", "{")
    assert(parsed == 0)
    receive("getConfig", "invalid")
    assert(parsed == 1)
    values["false"] = false
    receive("getConfig", "false")
    assert(parsed == 2 and calls.config == nil)
    values["{}"] = {}
    receive("getConfig", "{}")
    assert(calls.config == 1)
end)

test("deep nesting is refused before invoking the engine parser", function()
    reset("server")
    receive("getConfig", string.rep("[", 25) .. string.rep("]", 25))
    assert(parsed == 0 and calls.config == nil)
    local boundary = string.rep("[", 24) .. string.rep("]", 24)
    values[boundary] = {}
    receive("getConfig", boundary)
    assert(parsed == 1 and calls.config == 1)
end)

test("quoted delimiters and escaped quotes are not treated as nesting", function()
    reset("server")
    local json = '{"text":"escaped quote: \\" ' .. string.rep("[{}]", 30) .. '"}'
    values[json] = { text = "Safe text" }
    receive("getConfig", json)
    assert(parsed == 1 and calls.config == 1)
end)

test("oversize messages and unknown IDs are rejected before parsing", function()
    reset("server")
    values["{}"] = {}
    receive("getConfig", "{}", player(), 60001 * 8)
    receive("getConfig", string.rep(" ", 60001), player(), 1)
    receive("unknown", "{}")
    assert(parsed == 0 and calls.config == nil)
end)

test("invalid senders and unauthorized connection tests stay inert", function()
    reset("server")
    values["{}"] = {}
    local invalid = player()
    invalid.valid = false
    receive("getConfig", "{}", invalid)
    receive("testConnection", "{}", player(false))
    assert(calls.config == nil and calls.test == nil)
    receive("testConnection", "{}", player(true))
    assert(calls.test == 1)
end)

test("repeated administrative actions are throttled", function()
    reset("server")
    values["{}"] = {}
    local ply = player(true)
    receive("getConfig", "{}", ply)
    receive("getConfig", "{}", ply)
    assert(calls.config == 1)
    now = now + 2
    receive("getConfig", "{}", ply)
    assert(calls.config == 2)
end)

test("relay bodies are neither logged nor accepted with hostile nesting", function()
    reset("server")
    local json = '{"secret":"hidden-client-screenshot"}'
    values[json] = { secret = "hidden-client-screenshot" }
    receive("apiRelayChunk", json)
    assert(calls.chunk == 1 and #logs == 0)
    receive("apiRelayChunk", string.rep("[", 25) .. string.rep("]", 25))
    assert(calls.chunk == 1)
end)

test("client receiver shares the same parse and nesting protection", function()
    reset("client")
    receive("apiRelayResponse", "{")
    receive("apiRelayResponse", "invalid")
    receive("apiRelayResponse", string.rep("[", 25) .. string.rep("]", 25))
    assert(parsed == 1 and calls.response == nil)
    local json = '{"id":"response","status":200}'
    values[json] = { id = "response", status = 200 }
    receive("apiRelayResponse", json)
    assert(calls.response == 1 and #logs == 0)
end)

if #failures > 0 then error(table.concat(failures, "\n")) end
print("Net boundary regressions: " .. passes .. " passed")
