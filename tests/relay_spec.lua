-- These tests isolate our state/validation logic. Compression, JSON and GMod itself are mocked.
local now, timers, hooks, messages, requests, jsonValues, jsonSequence, localPlayer
local failures, passes = {}, 0
local chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"

local function base64(value)
    return ((value:gsub('.', function(char)
        local bits, byte = '', char:byte()
        for index = 8, 1, -1 do bits = bits .. (byte % 2 ^ index - byte % 2 ^ (index - 1) > 0 and '1' or '0') end
        return bits
    end) .. '0000'):gsub('%d%d%d?%d?%d?%d?', function(bits)
        if #bits < 6 then return '' end
        local index = 0
        for position = 1, 6 do if bits:sub(position, position) == '1' then index = index + 2 ^ (6 - position) end end
        return chars:sub(index + 1, index + 1)
    end) .. ({ '', '==', '=' })[#value % 3 + 1])
end

local function unbase64(value)
    return (value:gsub('[^' .. chars .. '=]', ''):gsub('.', function(char)
        if char == '=' then return '' end
        local bits, byte = '', chars:find(char, 1, true) - 1
        for index = 6, 1, -1 do bits = bits .. (byte % 2 ^ index - byte % 2 ^ (index - 1) > 0 and '1' or '0') end
        return bits
    end):gsub('%d%d%d?%d?%d?%d?%d?%d?', function(bits)
        if #bits ~= 8 then return '' end
        local byte = 0
        for position = 1, 8 do if bits:sub(position, position) == '1' then byte = byte + 2 ^ (8 - position) end end
        return string.char(byte)
    end))
end

local function player(id)
    return {
        valid = true,
        IsPlayer = function() return true end,
        SteamID64 = function() return id or "76561198012345678" end,
    }
end

local function advance(seconds)
    local target = now + seconds
    while true do
        local earliest, entry
        for name, timer in pairs(timers) do
            if timer.at <= target and (not entry or timer.at < entry.at) then earliest, entry = name, timer end
        end
        if not entry then break end
        now = entry.at
        if entry.count == 1 then timers[earliest] = nil
        else
            if entry.count > 1 then entry.count = entry.count - 1 end
            entry.at = now + entry.interval
        end
        entry.callback()
    end
    now = target
end

local function reset(realm)
    now, timers, hooks, messages, requests, jsonValues, jsonSequence = 100, {}, {}, {}, {}, {}, 0
    SERVER, CLIENT = realm == "server", realm == "client"
    isstring = function(value) return type(value) == "string" end
    isnumber = function(value) return type(value) == "number" end
    isbool = function(value) return type(value) == "boolean" end
    isfunction = function(value) return type(value) == "function" end
    istable = function(value) return type(value) == "table" end
    IsValid = function(value) return type(value) == "table" and value.valid == true end
    CurTime = function() return now end
    SysTime = CurTime
    localPlayer = player()
    LocalPlayer = function() return localPlayer end
    table.GetKeys = function(value)
        local keys = {}
        for key in pairs(value) do keys[#keys + 1] = key end
        return keys
    end
    timer = {
        Create = function(name, interval, count, callback)
            timers[name] = { at = now + interval, interval = interval, count = count, callback = callback }
        end,
        Remove = function(name) timers[name] = nil end,
    }
    hook = { Add = function(event, name, callback) hooks[event] = callback end }
    util = {
        TableToJSON = function(value)
            jsonSequence = jsonSequence + 1
            local json = string.rep(" ", value._bytes or 0) .. '{"mock":' .. jsonSequence .. '}'
            jsonValues[json] = value
            return json
        end,
        JSONToTable = function(json) return jsonValues[json] end,
        Compress = function(value) return "packed:" .. value end,
        Decompress = function(value, limit)
            assert(limit == 10 * 1024 * 1024, "Decompression must have the explicit memory cap")
            if value:sub(1, 7) ~= "packed:" or #value - 7 > limit then return nil end
            return value:sub(8)
        end,
        Base64Encode = function(value, inline)
            assert(inline == true, "GMod inserts newlines unless Base64Encode explicitly requests inline output")
            return base64(value)
        end,
        Base64Decode = unbase64,
    }
    gmInte = {
        config = { id = "server-one" },
        getPlayerFormat = function(ply) return { steamID64 = ply:SteamID64(), name = "Trusted server player" } end,
        SendNet = function(id, data, ply) messages[#messages + 1] = { id = id, data = data, player = ply } end,
        api = { requestAPI = function(params) requests[#requests + 1] = params end },
        logError = function() end,
    }
    loadGLua("lua/gmod_integration/core/net/sh_json.lua")
    loadGLua("lua/gmod_integration/core/api/" .. (SERVER and "sv_relay.lua" or "cl_relay.lua"))
end

local function image()
    return { screenshot = "YWJjZA==", title = "Test", captureData = { format = "jpeg", w = 1920, h = 1080, x = 0, y = 0, quality = 95 } }
end

local sequence = 0
local function chunks(kind, body)
    sequence = sequence + 1
    local json = util.TableToJSON(body)
    local encoded = base64(util.Compress(json))
    local count, packets = math.ceil(#encoded / 30000), {}
    for part = 1, count do
        packets[part] = {
            id = "test-" .. sequence, kind = kind, part = part, count = count, total = #encoded, rawBytes = #json,
            content = encoded:sub((part - 1) * 30000 + 1, part * 30000),
        }
    end
    return packets
end

local function send(ply, packets)
    for _, packet in ipairs(packets) do gmInte.receiveClientAPIChunk(ply, packet) end
end

local function test(name, callback)
    local ok, error = pcall(callback)
    if ok then passes = passes + 1
    else failures[#failures + 1] = name .. ": " .. tostring(error) end
end

test("self upload binds server and player identity and waits for acknowledgement", function()
    reset("server")
    local ply, body = player(), image()
    body.player = { steamID64 = "76561198999999999", userGroup = "superadmin" }
    body.serverID = "other-server"
    send(ply, chunks("screenshots", body))
    assert(#requests == 1 and #messages == 0)
    assert(requests[1].endpoint == "/clients/76561198012345678/servers/server-one/screenshots")
    assert(requests[1].body.player.steamID64 == ply:SteamID64() and requests[1].body.player.userGroup == nil)
    assert(requests[1].body.serverID == nil)
    requests[1].success(200, { secret = "do not echo stored payloads" })
    assert(#messages == 1 and messages[1].data.status == 200 and messages[1].data.body.secret == nil)
end)

test("screenshot acknowledgements keep only verified storage and Discord delivery outcomes", function()
    for _, outcome in ipairs({
        { saved = true, discordDelivered = true },
        { saved = true, discordDelivered = false, delivery = "not_configured" },
        { saved = true, discordDelivered = false, delivery = "unavailable" },
    }) do
        reset("server")
        local ply = player()
        send(ply, chunks("screenshots", image()))
        outcome.secret = "stored screenshot and credentials must not be echoed"
        outcome.url = "https://private.example/screenshot"
        requests[1].success(200, outcome)
        local body = messages[1].data.body
        assert(body.success == true and body.saved == true)
        assert(body.discordDelivered == outcome.discordDelivered and body.delivery == outcome.delivery)
        assert(body.secret == nil and body.url == nil)
    end
    reset("server")
    send(player(), chunks("screenshots", image()))
    requests[1].success(200, { saved = true, discordDelivered = false, delivery = "private exception details" })
    assert(messages[1].data.body.delivery == nil)
end)

test("unapproved operation and malformed metadata cannot dispatch", function()
    reset("server")
    local ply = player()
    send(ply, chunks("config", image()))
    gmInte.receiveClientAPIChunk(ply, nil)
    gmInte.receiveClientAPIChunk(ply, { id = "request" })
    local packet = chunks("screenshots", image())[1]
    packet.total = 8 * 1024 * 1024 + 1
    gmInte.receiveClientAPIChunk(ply, packet)
    assert(#requests == 0)
end)

test("invalid image metadata and base64 are rejected before side effects", function()
    reset("server")
    local body = image()
    body.captureData.w = -1
    send(player(), chunks("screenshots", body))
    body = image()
    body.screenshot = "not base64"
    send(player(), chunks("screenshots", body))
    assert(#requests == 0 and #messages == 2 and messages[1].data.status == 400)
end)

test("invalid senders cannot open a relay transfer", function()
    reset("server")
    local invalid = player()
    invalid.valid = false
    send(invalid, chunks("screenshots", image()))
    local nonPlayer = player()
    nonPlayer.IsPlayer = function() return false end
    send(nonPlayer, chunks("screenshots", image()))
    assert(#requests == 0 and #messages == 0)
end)

test("repeated or reordered chunks reject the transfer rather than duplicate it", function()
    reset("server")
    local ply, body = player(), image()
    body._bytes = 40000
    local packets = chunks("screenshots", body)
    assert(#packets > 1)
    gmInte.receiveClientAPIChunk(ply, packets[1])
    gmInte.receiveClientAPIChunk(ply, packets[1])
    gmInte.receiveClientAPIChunk(ply, packets[2])
    assert(#requests == 0 and #messages == 1 and messages[1].data.status == 400)
end)

test("duplicate completed transfer while awaiting acknowledgement is inert", function()
    reset("server")
    local ply, packets = player(), chunks("screenshots", image())
    send(ply, packets)
    send(ply, packets)
    assert(#requests == 1)
end)

test("metadata cannot change between chunks", function()
    reset("server")
    local ply, body = player(), image()
    body._bytes = 40000
    local packets = chunks("screenshots", body)
    gmInte.receiveClientAPIChunk(ply, packets[1])
    packets[2].kind = "bugs"
    gmInte.receiveClientAPIChunk(ply, packets[2])
    assert(#requests == 0 and messages[1].data.status == 400)
end)

test("global reservation bounds concurrent clients and disconnect releases it", function()
    reset("server")
    local clients = {}
    local packet = { id = "huge", kind = "screenshots", part = 1, count = 140, total = 4 * 1024 * 1024, rawBytes = 4 * 1024 * 1024, content = string.rep("A", 30000) }
    for index = 1, 5 do clients[index] = player(); gmInte.receiveClientAPIChunk(clients[index], packet) end
    assert(#requests == 0 and #messages == 1 and messages[1].data.status == 503)
    clients[1].valid = false
    hooks.PlayerDisconnected(clients[1])
    gmInte.receiveClientAPIChunk(player(), packet)
    assert(#messages == 1, "Disconnect must free the global reservation")
end)

test("timeouts release assemblies and permit a later retry", function()
    reset("server")
    local ply, body = player(), image()
    body._bytes = 40000
    gmInte.receiveClientAPIChunk(ply, chunks("screenshots", body)[1])
    advance(61)
    assert(messages[1].data.status == 504)
    send(ply, chunks("screenshots", image()))
    assert(#requests == 1)
end)

test("the global budget includes declared decompressed memory", function()
    reset("server")
    local packet = { id = "compressed", kind = "screenshots", part = 1, count = 2, total = 60000, rawBytes = 10 * 1024 * 1024, content = string.rep("A", 30000) }
    for _ = 1, 4 do gmInte.receiveClientAPIChunk(player(), packet) end
    assert(#requests == 0 and #messages == 1 and messages[1].data.status == 503)
end)

test("rate limiting applies to logical uploads, not individual chunks", function()
    reset("server")
    local ply = player()
    send(ply, chunks("screenshots", image()))
    requests[1].success(200, {})
    send(ply, chunks("screenshots", image()))
    assert(#requests == 1 and messages[2].data.status == 429)
    advance(11)
    send(ply, chunks("screenshots", image()))
    assert(#requests == 2)
end)

test("cancellation drops an incomplete transfer", function()
    reset("server")
    local ply, body = player(), image()
    body._bytes = 40000
    local packets = chunks("screenshots", body)
    gmInte.receiveClientAPIChunk(ply, packets[1])
    gmInte.cancelClientAPIRelay(ply, { id = packets[1].id })
    gmInte.receiveClientAPIChunk(ply, packets[2])
    assert(#requests == 0)
end)

test("errors derive realm and identifier from the sender", function()
    reset("server")
    local ply = player()
    send(ply, chunks("errors", { error = "Test", stack = {}, count = 1, uptime = 12, realm = "server", identifier = "spoofed" }))
    assert(#requests == 1 and requests[1].body.realm == "client")
    assert(requests[1].body.identifier == ply:SteamID64())
end)

test("decompression fails closed with an explicit output cap", function()
    reset("server")
    local called = false
    util.Decompress = function(_, maximum) called = true; assert(maximum == 10 * 1024 * 1024); return nil end
    send(player(), chunks("screenshots", image()))
    assert(called and #requests == 0 and messages[1].data.status == 400)
end)

test("declared JSON size and excessive nesting fail before parsing", function()
    reset("server")
    local malformed = chunks("screenshots", image())
    malformed[1].rawBytes = malformed[1].rawBytes + 1
    send(player(), malformed)
    assert(#requests == 0 and messages[1].data.status == 400)
    local json = string.rep("[", 25) .. string.rep("]", 25)
    local encoded = base64(util.Compress(json))
    util.JSONToTable = function() error("Nested input must be rejected before JSON parsing") end
    gmInte.receiveClientAPIChunk(player(), { id = "deep", kind = "errors", part = 1, count = 1, total = #encoded, rawBytes = #json, content = encoded })
    assert(#requests == 0 and messages[2].data.status == 400)
end)

test("bug report importance and text limits are enforced", function()
    reset("server")
    local body = { description = "Bug", importance = "critical", steps = "Step", expected = "Expected", actual = "Actual" }
    send(player(), chunks("bugs", body))
    assert(#requests == 1)
    body.importance = "invalid"
    send(player(), chunks("bugs", body))
    assert(#requests == 1 and messages[1].data.status == 400)
end)

test("bug report acknowledgements disclose only the saved report and bounded attachment outcome", function()
    for _, attachment in ipairs({ "none", "saved", "failed" }) do
        reset("server")
        local ply = player()
        local body = { description = "Bug", importance = "critical", steps = "Step", expected = "Expected", actual = "Actual" }
        send(ply, chunks("bugs", body))
        requests[1].success(200, {
            success = true, saved = true, attachment = attachment, description = "private report",
            token = "private credential", url = "https://private.example/capture", discordDelivered = true
        })
        local result = messages[1].data.body
        assert(result.success == true and result.saved == true and result.attachment == attachment)
        assert(result.description == nil and result.token == nil and result.url == nil and result.discordDelivered == nil)
        assert(requests[1].body.player.steamID64 == ply:SteamID64())
    end
    reset("server")
    send(player(), chunks("bugs", { description = "Bug", importance = "critical", steps = "Step", expected = "Expected", actual = "Actual" }))
    requests[1].success(200, { saved = true, attachment = "private storage exception" })
    assert(messages[1].data.body.attachment == nil and messages[1].data.body.saved == nil)
end)

test("invalid optional captures do not discard a valid bug report or forward malformed capture contents", function()
    for _, screenshot in ipairs({ "private invalid data", { invalid = true }, { screenshot = "private malformed image" } }) do
        reset("server")
        local ply = player()
        send(ply, chunks("bugs", {
            description = "Bug", importance = "critical", steps = "Step", expected = "Expected", actual = "Actual",
            player = { steamID64 = "76561198999999999" }, screenshot = screenshot
        }))
        assert(#requests == 1 and requests[1].body.description == "Bug")
        assert(requests[1].body.player.steamID64 == ply:SteamID64())
        assert(requests[1].body.screenshot.invalid == true and requests[1].body.screenshot.screenshot == nil)
        requests[1].success(200, { saved = true, attachment = "failed" })
        assert(messages[1].data.body.attachment == "failed")
    end
end)

test("forwarded request gets enough time for queue and server acknowledgement", function()
    reset("server")
    send(player(), chunks("screenshots", image()))
    advance(60)
    assert(#messages == 0)
    requests[1].failed(503, { error = "offline", token = "hidden" })
    assert(messages[1].data.status == 503 and messages[1].data.body.token == nil)
end)

test("client success only fires on matching acknowledgement and once", function()
    reset("client")
    local success, failure = 0, 0
    local id = gmInte.sendClientAPI({ method = "POST", endpoint = "/clients/me/servers/server-one/screenshots", body = image(), success = function() success = success + 1 end, failed = function() failure = failure + 1 end })
    advance(0.1)
    assert(#messages == 1 and success == 0)
    gmInte.receiveClientAPIResponse({ id = "other", status = 200 })
    assert(success == 0)
    gmInte.receiveClientAPIResponse({ id = id, status = 200 })
    gmInte.receiveClientAPIResponse({ id = id, status = 200 })
    advance(100)
    assert(success == 1 and failure == 0)
end)

test("client success without a success callback never invokes the failure callback", function()
    reset("client")
    local failure = 0
    local id = gmInte.sendClientAPI({ method = "POST", endpoint = "/clients/me/servers/server-one/errors", body = {}, failed = function() failure = failure + 1 end })
    gmInte.receiveClientAPIResponse({ id = id, status = 200 })
    assert(failure == 0)
end)

test("client concurrent requests, unauthorized routes and oversize payloads fail", function()
    reset("client")
    local codes = {}
    local function failed(code) codes[#codes + 1] = code end
    gmInte.sendClientAPI({ method = "GET", endpoint = "/servers/server-one/config", failed = failed })
    gmInte.sendClientAPI({ method = "POST", endpoint = "/clients/me/servers/server-one/bugs", body = { _bytes = 10 * 1024 * 1024 }, failed = failed })
    gmInte.sendClientAPI({ method = "POST", endpoint = "/clients/me/servers/server-one/bugs", body = {}, failed = failed })
    gmInte.sendClientAPI({ method = "POST", endpoint = "/clients/me/servers/server-one/bugs", body = {}, failed = failed })
    assert(codes[1] == 403 and codes[2] == 413 and codes[3] == 429)
end)

test("client cancellation stops chunking and reports a cancelled outcome", function()
    reset("client")
    local code
    local id = gmInte.sendClientAPI({ method = "POST", endpoint = "/clients/me/servers/server-one/bugs", body = { _bytes = 50000 }, failed = function(status) code = status end })
    advance(0.05)
    gmInte.cancelClientAPI(id)
    local count = #messages
    advance(100)
    assert(code == 499 and #messages == count and messages[count].id == "apiRelayCancel")
end)

test("client timeout and shutdown settle pending callbacks", function()
    reset("client")
    local code
    gmInte.sendClientAPI({ method = "POST", endpoint = "/clients/me/servers/server-one/bugs", body = {}, failed = function(status) code = status end })
    advance(91)
    assert(code == 504)
    gmInte.sendClientAPI({ method = "POST", endpoint = "/clients/me/servers/server-one/bugs", body = {}, failed = function(status) code = status end })
    hooks.ShutDown()
    assert(code == 503)
end)

if #failures > 0 then error(table.concat(failures, "\n")) end
print("Relay boundary regressions: " .. passes .. " passed")
