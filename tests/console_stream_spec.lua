-- Mocked native output and the actual WebSocket dispatcher; no GMod engine output is emulated.
local nativePrint, loadSource = print, loadGLua
local clock, timers, hooks, sockets, encoded, serial, output, sent, options
local passes = 0
local function clone(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = clone(child) end
    return result
end
local function reset(settings)
    options = settings or {}
    clock, timers, hooks, sockets, encoded, serial, output, sent = 0, {}, {}, {}, {}, 0, {}, {}
    SERVER, CLIENT = true, false
    isstring = function(value) return type(value) == "string" end
    istable = function(value) return type(value) == "table" end
    isnumber = function(value) return type(value) == "number" end
    isfunction = function(value) return type(value) == "function" end
    isbool = function(value) return type(value) == "boolean" end
    IsColor = function(value) return type(value) == "table" and value.color == true end
    IsValid = function(value) return value and value.valid == true end
    SysTime = function() return clock end
    os.time = function() return 1700000000 + math.floor(clock) end
    math.Rand = function(minimum) return minimum end
    for _, name in ipairs({ "print", "Msg", "MsgN", "MsgC" }) do
        _G[name] = function(...)
            output[#output + 1] = { name = name, values = { ... } }
            return "native-" .. name
        end
    end
    hook = {
        Add = function(event, id, callback)
            hooks[event] = hooks[event] or {}
            hooks[event][id] = callback
        end,
        Run = function(event, ...)
            for _, callback in pairs(hooks[event] or {}) do callback(...) end
        end,
    }
    timer = {
        Create = function(id, _, _, callback) timers[id] = callback end,
        Simple = function() end,
    }
    util = {
        TableToJSON = function(value)
            serial = serial + 1
            local key = "json:" .. serial
            encoded[key] = clone(value)
            return key
        end,
        JSONToTable = function(key) return clone(encoded[key]) end,
    }
    player = { GetAll = function() return {} end }
    file = { Write = function(_, data) options.persisted = util.JSONToTable(data) end }
    gmInte = {
        config = {}, version = "5.2.8", previusVersion = "5.2.8", useDataConfig = true,
        log = function() end, logWarning = function() end, logError = function() end, logHint = function() end,
        isPrivateIP = function() return true end, loadTranslations = function() end,
        getTranslation = function(_, fallback) return fallback end,
        api = { post = function(_, body) options.synced = body end },
    }
    require = function() end
    GWSockets = { createWebSocket = function()
        local socket = { connected = false, writes = {} }
        function socket:setHeader() end
        function socket:isConnected() return self.connected end
        function socket:open() end
        function socket:close()
            self.connected = false
            if self.onDisconnected then self:onDisconnected() end
        end
        function socket:write(json)
            if options.sendThrows then error("synthetic write failure") end
            if options.echoDuringSend then print("transport debug") end
            local packet = util.JSONToTable(json)
            self.writes[#self.writes + 1] = packet
            if packet.action == "console_live_exporter" then sent[#sent + 1] = packet.data.data end
        end
        sockets[#sockets + 1] = socket
        return socket
    end }
    loadSource("lua/gmod_integration/core/config/sv_default_config.lua")
    gmInte.config.id, gmInte.config.token, gmInte.config.websocketFQDN = "fixture-server", "fixture-credential", "127.0.0.1"
    gmInte.config.consoleLiveExporter, gmInte.enableConsoleLiveExporter = true, true
    loadSource("lua/gmod_integration/core/api/sv_websocket.lua")
    loadSource("lua/gmod_integration/modules/console_live_exporter/sv_main.lua")
    gmInte.setupWebSocket()
end
local function message(packet, socket)
    (socket or sockets[#sockets]):onMessage(util.TableToJSON(packet))
end
local function ready()
    local socket = sockets[#sockets]
    socket.connected = true
    socket:onConnected()
    message({ action = "addon.ready", protocol = 1 })
    return socket
end
local function start(seconds)
    message({ method = "wsConsoleStream", enabled = true, expiresAt = os.time() * 1000 + (seconds or 25) * 1000 })
end
local function flush(seconds)
    clock = clock + (seconds or 0)
    timers["gmInte:ConsoleStream:Flush"]()
end
local function stopped()
    assert(gmInte.config.consoleLiveExporter == false and gmInte.enableConsoleLiveExporter == false)
end
local function test(name, run)
    reset()
    local ok, problem = pcall(run)
    assert(ok, name .. ": " .. tostring(problem))
    passes = passes + 1
    nativePrint("ok console stream: " .. name)
end

test("starts disabled and accepts stream commands only after authenticated protocol readiness", function()
    stopped()
    start()
    stopped()
    assert(print("local only") == "native-print")
    flush()
    assert(#sent == 0 and #output == 1)
    ready()
    start()
    assert(gmInte.config.consoleLiveExporter and gmInte.enableConsoleLiveExporter)
    print("visible", 42, false)
    assert(#sent == 0)
    flush()
    assert(#sent == 1 and sent[1] == "visible\t42\tfalse\n")
end)

test("rejects malformed, unexpected, expired, oversized and nonfinite lease input", function()
    ready()
    local now = os.time() * 1000
    for _, packet in ipairs({
        {}, { method = "wsConsoleStream", enabled = "true", expiresAt = now + 1000 },
        { method = "wsConsoleStream", enabled = true },
        { method = "wsConsoleStream", enabled = true, expiresAt = now },
        { method = "wsConsoleStream", enabled = true, expiresAt = now - 1 },
        { method = "wsConsoleStream", enabled = true, expiresAt = now + 35001 },
        { method = "wsConsoleStream", enabled = true, expiresAt = now + 1000.5 },
        { method = "wsConsoleStream", enabled = true, expiresAt = math.huge },
        { method = "wsConsoleStream", enabled = true, expiresAt = 0 / 0 },
        { method = "wsConsoleStream", enabled = false, expiresAt = 1 },
        { method = "wsConsoleStream", enabled = true, expiresAt = now + 1000, extra = true },
    }) do
        assert(not gmInte.validateConsoleStream(packet))
        message(packet)
        stopped()
    end
    assert(not gmInte.validateConsoleStream(false))
    gmInte.config.consoleLiveExporter, gmInte.enableConsoleLiveExporter = true, true
    print("a local flag cannot create a remote lease")
    flush()
    stopped()
    assert(#sent == 0)
end)

test("captures Lua print, Msg, MsgN and MsgC while preserving native output and skipping colors", function()
    ready()
    start()
    assert(print("one") == "native-print")
    assert(Msg("two", 3) == "native-Msg")
    assert(MsgN("four") == "native-MsgN")
    assert(MsgC({ color = true }, "five", { color = true }, "six") == "native-MsgC")
    flush()
    assert(#sent == 4 and #output == 4)
    assert(sent[1] == "one\n" and sent[2] == "two3" and sent[3] == "four\n" and sent[4] == "fivesix")
end)

test("bounds message bytes and does not recurse into cyclic tables or unsafe tostring metamethods", function()
    ready()
    start()
    print(string.rep("x", 100000))
    local cyclic = {}; cyclic.self = cyclic
    print(cyclic, setmetatable({}, { __tostring = function() error("must not traverse or serialize tables") end }))
    flush()
    assert(#sent == 2 and #sent[1] == 32768)
    assert(sent[2] == "<table>\t<table>\n")
end)

test("bounds queued bytes and messages and sends at most ten messages and 64 KiB per second", function()
    ready()
    start()
    for _ = 1, 1000 do print("small") end
    flush()
    assert(#sent == 10)
    flush(0.5)
    assert(#sent == 10)
    for _ = 1, 7 do flush(1) end
    assert(#sent == 64)
    gmInte.stopConsoleStream()
    start()
    for _ = 1, 20 do print(string.rep("x", 100000)) end
    flush()
    assert(#sent == 66 and #sent[65] + #sent[66] == 65536)
    flush(1)
    assert(#sent == 66)
end)

test("suppresses transport logging recursion and disables silently on failed sends", function()
    reset({ echoDuringSend = true })
    ready()
    start()
    print("only this is forwarded")
    flush()
    flush(1)
    assert(#sent == 1 and #output == 2)
    options.sendThrows = true
    print("will fail")
    flush(1)
    stopped()
    assert(#sent == 1 and #output == 3)
end)

test("close discards pending output and expiry disables even if the gateway disappears", function()
    ready()
    start()
    print("discard on close")
    message({ method = "wsConsoleStream", enabled = false, expiresAt = 0 })
    stopped()
    start(35)
    print("discard on expiry")
    flush(30)
    stopped()
    start()
    flush()
    assert(#sent == 0)
end)

test("renews an existing lease without losing queued output and stops after the final renewal", function()
    ready()
    start(10)
    clock = 5
    start(10)
    print("lease renewed")
    flush(6)
    assert(#sent == 1)
    print("expired queue")
    flush(4)
    stopped()
    assert(#sent == 1)
end)

test("disconnect, connection errors, replacement, credential rotation and shutdown reset the stream", function()
    for _, event in ipairs({ "disconnect", "error", "replace", "credentials", "shutdown" }) do
        reset()
        local socket = ready()
        start()
        print("never replay this")
        if event == "disconnect" then socket:close()
        elseif event == "error" then socket:onError()
        elseif event == "replace" then gmInte.setupWebSocket()
        elseif event == "credentials" then
            gmInte.config.token = "new-fixture-credential"
            hook.Run("GmodIntegration:Websocket:Restart")
        else hook.Run("ShutDown") end
        stopped()
        flush(1)
        assert(#sent == 0)
    end
end)

test("a stale socket cannot stop or renew the replacement connection's subscription", function()
    local oldSocket = ready()
    start()
    gmInte.setupWebSocket()
    ready()
    start()
    oldSocket:onDisconnected()
    oldSocket:onError()
    message({ method = "wsConsoleStream", enabled = false, expiresAt = 0 }, oldSocket)
    assert(gmInte.config.consoleLiveExporter and gmInte.enableConsoleLiveExporter)
    print("current subscription")
    flush()
    assert(#sent == 1 and sent[1] == "current subscription\n")
end)

test("stream activation is never saved or synchronized as an in-game configuration setting", function()
    ready()
    loadSource("lua/gmod_integration/core/config/sv_settings.lua")
    start()
    assert(gmInte.config.consoleLiveExporter)
    assert(not gmInte.validateRemoteSetting("ig_consoleLiveExporter", true))
    assert(not gmInte.saveSetting("consoleLiveExporter", true))
    assert(gmInte.saveSetting("debug", true))
    assert(gmInte.config.consoleLiveExporter == true)
    assert(options.persisted.consoleLiveExporter == false)
    assert(options.synced.consoleLiveExporter == nil)
end)

test("Lua auto-refresh removes previous wrappers and resets the subscription", function()
    ready()
    start()
    print("discard old wrapper queue")
    loadSource("lua/gmod_integration/modules/console_live_exporter/sv_main.lua")
    stopped()
    start()
    print("only once")
    flush()
    assert(#sent == 1 and sent[1] == "only once\n" and #output == 2)
end)

nativePrint("console stream mocked tests passed: " .. passes)
