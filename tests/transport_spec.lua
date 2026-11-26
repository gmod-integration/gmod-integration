-- Mocked Lua transport tests. These do not exercise Garry's Mod or the GWSockets binary.
local clock, timers, sockets, serialized, serial, observations
local passed = 0
local originalLoad = loadGLua

local function clone(value)
    if type(value) ~= 'table' then return value end
    local copy = {}
    for key, child in pairs(value) do copy[key] = clone(child) end
    return copy
end

local function reset(options)
    options = options or {}
    clock, timers, sockets, serialized, serial, observations = 0, {}, {}, {}, 0, { deferred = {}, errors = {}, hints = {} }
    SERVER, CLIENT = true, false
    isstring = function(value) return type(value) == 'string' end
    istable = function(value) return type(value) == 'table' end
    isnumber = function(value) return type(value) == 'number' end
    isfunction = function(value) return type(value) == 'function' end
    isbool = function(value) return type(value) == 'boolean' end
    IsValid = function(value) return type(value) == 'table' and value.valid ~= false end
    SysTime = function() return clock end
    os.time = function() return 1700000000 + math.floor(clock) end
    math.Rand = function(minimum) return minimum end
    HTTP = function() error('HTTP must never be used') end
    http = { Fetch = function() error('HTTP Fetch must never be used') end }
    local hooks = {}
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
        Simple = function(_, callback) observations.deferred[#observations.deferred + 1] = callback end,
    }
    util = {
        TableToJSON = function(value)
            serial = serial + 1
            local padding = type(value.body) == 'table' and value.body.padding or ''
            local key = 'json:' .. serial .. (padding or '')
            serialized[key] = clone(value)
            return key
        end,
        JSONToTable = function(value) return clone(serialized[value]) end,
    }
    file = { Write = function(_, value) observations.persisted = util.JSONToTable(value) end }
    player = { GetAll = function() return {} end, GetBySteamID64 = function() return observations.player end }
    game = { ConsoleCommand = function(command)
        observations.consoleCalls = (observations.consoleCalls or 0) + 1
        if options.consoleFailure then error('console failure') end
        observations.commands = (observations.commands or 0) + 1
        observations.command = command
    end }
    gmInte = {
        config = {}, version = '5.2.8', previusVersion = '5.2.8', useDataConfig = true,
        log = function(message)
            observations.logs = observations.logs or {}
            observations.logs[#observations.logs + 1] = message
        end, logWarning = function() end,
        logError = function(message) observations.errors[#observations.errors + 1] = message end,
        logHint = function(message) observations.hints[#observations.hints + 1] = message end,
        getTranslation = function(_, fallback) return fallback end,
        loadTranslations = function() end,
        compareVersion = function() return 0 end,
        SendNet = function(id, data) observations.net = { id = id, data = data } end,
    }
    originalLoad('lua/gmod_integration/core/utils/sh_utils.lua')
    originalLoad('lua/gmod_integration/core/config/sv_default_config.lua')
    gmInte.config.id = 'server-id'
    gmInte.config.token = 'secret-token'
    gmInte.config.websocketFQDN = '127.0.0.1:53137'
    GWSockets = options.noModule and nil or {
        createWebSocket = function(url)
            local socket = { url = url, headers = {}, writes = {}, connected = false }
            function socket:setHeader(key, value) self.headers[key] = value end
            function socket:isConnected() return self.connected end
            function socket:open() self.opened = true end
            function socket:close()
                self.connected = false
                if self.onDisconnected then self:onDisconnected() end
            end
            function socket:write(value)
                if options.writeFailure then error('write failure') end
                self.writes[#self.writes + 1] = value
            end
            sockets[#sockets + 1] = socket
            return socket
        end,
    }
    if options.noModule then GWSockets = nil end
    if options.invalidModule then GWSockets.createWebSocket = nil end
    require = function() if options.noModule or options.loadFailure then error('private binary loader failure') end end
    originalLoad('lua/gmod_integration/core/api/sh_api.lua')
    originalLoad('lua/gmod_integration/core/api/sv_websocket.lua')
    local playerMeta = {}
    FindMetaTable = function() return playerMeta end
    originalLoad('lua/gmod_integration/core/utils/sh_player_meta.lua')
    observations.playerMeta = playerMeta
    originalLoad('lua/gmod_integration/modules/console_commands/sv_rcon.lua')
end

local function message(socket, value)
    socket:onMessage(util.TableToJSON(value))
end
local function ready(socket)
    socket.connected = true
    socket:onConnected()
    message(socket, { action = 'addon.ready', protocol = 1 })
end
local function tick(seconds)
    clock = clock + seconds
    timers['gmInte:WebSocket:CheckConnection']()
end
local function test(name, run)
    reset()
    local ok, problem = pcall(run)
    assert(ok, name .. ': ' .. tostring(problem))
    passed = passed + 1
    print('ok transport: ' .. name)
end

test('recognizes only localhost and canonical private or loopback IPv4 addresses', function()
    for _, host in ipairs({ 'localhost', '10.0.0.0', '10.255.255.255', '127.0.0.1', '127.255.255.255', '192.168.0.1', '172.16.0.1', '172.31.255.255' }) do
        assert(gmInte.isPrivateIP(host), host)
    end
    for _, host in ipairs({ '8.8.8.8', '172.15.0.1', '172.32.0.1', '192.169.0.1', '169.254.0.1', '0.0.0.0', '10.example.com', '192.168.example.com', '127.example.com', '172.foo', '10.0.0', '10.0.0.1.example', '10.0.0.256', '10.0.0.-1', '10.0.0.01', '010.0.0.1', '10.0.0.1.', '10.0.0.1:80', ' 127.0.0.1', '127.1', '0x7f000001', '[::1]', '' }) do
        assert(not gmInte.isPrivateIP(host), host)
    end
    assert(not gmInte.isPrivateIP(nil) and not gmInte.isPrivateIP(false) and not gmInte.isPrivateIP(127) and not gmInte.isPrivateIP({}))
end)

test('keeps hostname lookalikes on TLS and private IPv4 development sockets local', function()
    for _, host in ipairs({ '10.example.com', '192.168.example.com', '127.example.com', '172.foo', '10.0.0.256', '010.0.0.1', '172.32.0.1', 'ws.example.com' }) do
        gmInte.config.websocketFQDN = host .. ':53137'
        assert(gmInte.setupWebSocket())
        assert(sockets[#sockets].url == 'wss://' .. host .. ':53137', host)
    end
    for _, host in ipairs({ 'localhost', '10.0.0.1', '127.0.0.1', '192.168.0.1', '172.16.0.1', '172.31.0.1' }) do
        gmInte.config.websocketFQDN = host .. ':53137'
        assert(gmInte.setupWebSocket())
        assert(sockets[#sockets].url == 'ws://' .. host .. ':53137', host)
    end
end)

test('waits for protocol readiness, resolves placeholders and correlates one response', function()
    local calls = 0
    local id = gmInte.api.get('/servers/:serverID', function(code, body)
        calls = calls + 1
        assert(code == 200 and body.name == 'Test server')
    end)
    assert(type(id) == 'string' and #id <= 96)
    assert(gmInte.setupWebSocket())
    local socket = sockets[1]
    assert(socket.url == 'ws://127.0.0.1:53137')
    assert(socket.headers.token == 'secret-token' and socket.headers['gmod-integrations-version'] == '5.2.8')
    socket.connected = true
    socket:onConnected()
    assert(not gmInte.aprovedCredentials and #socket.writes == 0)
    message(socket, { action = 'addon.ready', protocol = 2 })
    assert(not gmInte.aprovedCredentials)
    ready(socket)
    assert(gmInte.aprovedCredentials and #socket.writes == 1)
    local request = util.JSONToTable(socket.writes[1])
    assert(request.endpoint == '/servers/server-id' and request.action == 'addon.request' and request.body == nil)
    message(socket, { action = 'addon.response', id = id, status = 200, body = { name = 'Test server' } })
    message(socket, { action = 'addon.response', id = id, status = 200, body = {} })
    assert(calls == 1)
end)

test('rejects missing binary and missing credentials without HTTP fallback', function()
    reset({ noModule = true })
    local status
    assert(gmInte.api.get('/servers/:serverID', nil, function(code) status = code end) == false)
    assert(status == 503 and gmInte.setupWebSocket() == false)
    reset()
    gmInte.config.token = ''
    assert(gmInte.api.get('/servers/:serverID', nil, function(code) status = code end) == false)
    assert(status == 401)
end)

test('treats absent, failed and incompatible GWSockets modules as a required dependency', function()
    for _, options in ipairs({ { noModule = true }, { loadFailure = true }, { invalidModule = true } }) do
        reset(options)
        assert(gmInte.hasWebsocketModule() == false)
        local failure
        assert(gmInte.api.get('/servers/:serverID', nil, function(code, body) failure = { code, body } end) == false)
        assert(failure[1] == 503 and failure[2].error == 'gwsockets_required')
        assert(gmInte.setupWebSocket() == false and #sockets == 0)
        assert(#observations.deferred == 1)
        observations.deferred[1]()
        assert(#observations.errors == 1 and observations.errors[1]:find('mandatory', 1, true))
        assert(observations.errors[1]:find('all connected', 1, true))
        assert(observations.hints[1]:find('garrysmod/lua/bin', 1, true))
        assert(observations.hints[1]:find('fully stop and restart', 1, true))
        assert(observations.hints[2]:find('installation#dll', 1, true))
        local output = table.concat(observations.errors) .. table.concat(observations.hints)
        assert(not output:find('private binary loader failure', 1, true) and not output:find('secret-token', 1, true))
    end
    reset()
    assert(gmInte.hasWebsocketModule() == true and gmInte.logWebsocketRequirement() == false)
    assert(#observations.deferred == 0 and #observations.errors == 0 and #observations.hints == 0)
end)

test('expires queued requests and bounds the queue count', function()
    local statuses = {}
    for _ = 1, 128 do assert(gmInte.api.get('/servers/:serverID', nil, function(code) statuses[#statuses + 1] = code end)) end
    assert(gmInte.api.get('/servers/:serverID', nil, function(code) statuses[#statuses + 1] = code end) == false)
    assert(statuses[1] == 429)
    tick(31)
    assert(#statuses == 129 and statuses[129] == 504)
    assert(gmInte.api.get('/servers/:serverID'))
end)

test('rejects oversized packets and limits queued bytes', function()
    local status
    assert(gmInte.api.post('/servers/:serverID/status', { padding = string.rep('x', 12 * 1024 * 1024) }, nil, function(code) status = code end) == false)
    assert(status == 413)
    local body = { padding = string.rep('x', 9 * 1024 * 1024) }
    assert(gmInte.api.post('/servers/:serverID/status', body))
    assert(gmInte.api.post('/servers/:serverID/status', body))
    assert(gmInte.api.post('/servers/:serverID/status', body, nil, function(code) status = code end) == false)
    assert(status == 429)
end)

test('dispatches at most four queued requests and frees slots in FIFO order', function()
    local ids = {}
    for index = 1, 6 do ids[index] = gmInte.api.get('/servers/:serverID') end
    gmInte.setupWebSocket()
    local socket = sockets[1]
    ready(socket)
    assert(#socket.writes == 4)
    assert(util.JSONToTable(socket.writes[4]).id == ids[4])
    local seventh = gmInte.api.get('/servers/:serverID')
    assert(#socket.writes == 4)
    message(socket, { action = 'addon.response', id = ids[2], status = 200, body = {} })
    assert(#socket.writes == 5 and util.JSONToTable(socket.writes[5]).id == ids[5])
    message(socket, { action = 'addon.response', id = ids[1], status = 200, body = {} })
    assert(#socket.writes == 6 and util.JSONToTable(socket.writes[6]).id == ids[6])
    message(socket, { action = 'addon.response', id = ids[3], status = 200, body = {} })
    assert(#socket.writes == 7 and util.JSONToTable(socket.writes[7]).id == seventh)
end)

test('a pending timeout frees a slot for a newer queued request', function()
    gmInte.setupWebSocket()
    local socket = sockets[1]
    ready(socket)
    for _ = 1, 4 do assert(gmInte.api.get('/servers/:serverID')) end
    clock = 20
    local queuedID = gmInte.api.get('/servers/:serverID')
    assert(#socket.writes == 4)
    tick(11)
    assert(#socket.writes == 5 and util.JSONToTable(socket.writes[5]).id == queuedID)
end)

test('does not replay a request whose delivery became uncertain', function()
    gmInte.setupWebSocket()
    local first = sockets[1]
    ready(first)
    local failures = 0
    gmInte.api.post('/servers/:serverID/start', {}, nil, function(code, body)
        failures = failures + 1
        assert(code == 503 and body.delivery == 'uncertain')
    end)
    first:close()
    assert(failures == 1 and not gmInte.aprovedCredentials)
    gmInte.api.get('/servers/:serverID')
    tick(1)
    assert(#sockets == 2)
    ready(sockets[2])
    assert(#sockets[2].writes == 1)
    assert(util.JSONToTable(sockets[2].writes[1]).method == 'GET')
end)

test('timeouts release pending slots and ignore late responses', function()
    gmInte.setupWebSocket()
    local socket = sockets[1]
    ready(socket)
    local failures, successes = 0, 0
    local id = gmInte.api.get('/servers/:serverID', function() successes = successes + 1 end, function(code, body)
        failures = failures + 1
        assert(code == 504 and body.delivery == 'uncertain')
    end)
    tick(31)
    message(socket, { action = 'addon.response', id = id, status = 200, body = {} })
    assert(failures == 1 and successes == 0)
end)

test('write failures invalidate the socket and reconnect without replay', function()
    reset({ writeFailure = true })
    gmInte.setupWebSocket()
    ready(sockets[1])
    local status
    gmInte.api.post('/servers/:serverID/start', {}, nil, function(code, body)
        status = code
        assert(body.error == 'write_failed' and body.delivery == 'uncertain')
    end)
    assert(status == 503 and not gmInte.aprovedCredentials)
    tick(1)
    assert(#sockets == 2 and #sockets[2].writes == 0)
end)

test('reconnects after missing readiness and applies exponential backoff', function()
    gmInte.setupWebSocket()
    tick(16)
    assert(#sockets == 1)
    tick(1)
    assert(#sockets == 2)
    sockets[2]:onError()
    tick(1)
    assert(#sockets == 2)
    tick(1)
    assert(#sockets == 3)
end)

test('credential rotation clears unsent work and rejects stale ready packets', function()
    gmInte.setupWebSocket()
    local previous = sockets[1]
    local failures = 0
    gmInte.api.get('/servers/:serverID', nil, function(_, body)
        failures = failures + 1
        assert(body.delivery == 'not_sent')
    end)
    gmInte.config.token = ''
    hook.Run('GmodIntegration:Websocket:Restart')
    ready(previous)
    assert(failures == 1 and not gmInte.aprovedCredentials and gmInte.websocket == nil)
end)

test('rejects unknown and malformed remote commands before existing handlers', function()
    gmInte.setupWebSocket()
    local socket = sockets[1]
    ready(socket)
    local calls = 0
    gmInte.arbitraryFunction = function() error('untrusted dispatcher') end
    gmInte.wsAuthorizedRcon = function() calls = calls + 1 return true, 'executed' end
    socket:onMessage('{')
    message(socket, { method = 'arbitraryFunction' })
    message(socket, { method = 'wsRcon', command = 'status', steamID = '76561198000000001' })
    message(socket, { method = 'wsAuthorizedRcon', command = {}, steamID = '76561198000000001' })
    message(socket, { method = 'wsAuthorizedRcon', command = 'status', steamID = '76561198000000001', requestID = '3a918b48-ff6f-4ed4-b2b9-f4b722840f04', expiresAt = os.time() * 1000 + 5000 })
    assert(calls == 1)
end)

test('accepts only authenticated bounded access-refresh invalidations without supplied grants', function()
    gmInte.setupWebSocket()
    local socket = sockets[1]
    local calls = {}
    gmInte.wsRefreshPlayerAccess = function(data) calls[#calls + 1] = data end
    message(socket, { method = 'wsRefreshPlayerAccess' })
    assert(#calls == 0)
    ready(socket)
    for _, packet in ipairs({
        { method = 'wsRefreshPlayerAccess', steamID = false },
        { method = 'wsRefreshPlayerAccess', steamID = 76561198000000001 },
        { method = 'wsRefreshPlayerAccess', steamID = '' },
        { method = 'wsRefreshPlayerAccess', steamID = '7656119800000000' },
        { method = 'wsRefreshPlayerAccess', steamID = '765611980000000010' },
        { method = 'wsRefreshPlayerAccess', steamID = '7656119800000000x' },
        { method = 'wsRefreshPlayerAccess', steamID = string.rep('1', 1024) },
        { method = 'wsRefreshPlayerAccess', bypassMaintenance = true },
        { method = 'wsRefreshPlayerAccess', steamID = '76561198000000001', access = true },
    }) do message(socket, packet) end
    assert(#calls == 0)
    message(socket, { method = 'wsRefreshPlayerAccess', steamID = '76561198000000001' })
    message(socket, { method = 'wsRefreshPlayerAccess' })
    message(socket, { method = 'wsRefreshPlayerAccess' })
    assert(#calls == 3 and calls[1].steamID == '76561198000000001' and calls[2].steamID == nil)
    socket:onDisconnected()
    message(socket, { method = 'wsRefreshPlayerAccess' })
    assert(#calls == 3)
end)

local function rconPacket(changes)
    local packet = { method = 'wsAuthorizedRcon', command = 'status', steamID = '76561198000000001', requestID = '3a918b48-ff6f-4ed4-b2b9-f4b722840f04', expiresAt = os.time() * 1000 + 5000 }
    for key, value in pairs(changes or {}) do packet[key] = value end
    return packet
end
local function onlinePlayer(group)
    observations.player = setmetatable({ group = group, GetUserGroup = function(self) return self.group end }, { __index = observations.playerMeta })
end

local function panelRconPacket(changes)
    local packet = { method = 'wsPanelRcon', command = 'status', actorDiscordID = '123456789012345678', requestID = '3a918b48-ff6f-4ed4-b2b9-f4b722840f04', expiresAt = os.time() * 1000 + 5000 }
    for key, value in pairs(changes or {}) do packet[key] = value end
    return packet
end

test('panel RCON executes on an empty server only after authenticated protocol readiness', function()
    player.GetBySteamID64 = function() error('Panel RCON must not look up a game player') end
    gmInte.setupWebSocket()
    local socket = sockets[1]
    local packet = panelRconPacket({ command = 'echo private-panel-command-value' })
    message(socket, packet)
    assert(observations.commands == nil and #socket.writes == 0)
    ready(socket)
    message(socket, packet)
    local ack = util.JSONToTable(socket.writes[#socket.writes])
    assert(ack.action == 'addon.command-result' and ack.method == 'wsPanelRcon' and ack.id == packet.requestID and ack.ok == true and ack.code == 'executed')
    assert(observations.commands == 1 and observations.command == packet.command .. '\n')
    local logs = table.concat(observations.logs or {}, '\n')
    assert(logs:find(packet.actorDiscordID, 1, true) and not logs:find(packet.command, 1, true))
    message(socket, packet)
    assert(observations.commands == 1)
    socket:onDisconnected()
    message(socket, panelRconPacket({ requestID = '4a918b48-ff6f-4ed4-b2b9-f4b722840f04' }))
    assert(observations.commands == 1)
end)

test('panel RCON does not depend on game administrator groups and Discord still rejects an offline player', function()
    gmInte.config.adminRank = {}
    local denied, code = gmInte.wsAuthorizedRcon(rconPacket())
    assert(denied == false and code == 'permission_denied' and observations.commands == nil)
    local ok, accepted = gmInte.wsPanelRcon(panelRconPacket({ requestID = '4a918b48-ff6f-4ed4-b2b9-f4b722840f04' }))
    assert(ok == true and accepted == 'executed' and observations.commands == 1)
end)

test('panel RCON rejects malformed fields, identities, command bytes and deadlines', function()
    for _, changes in ipairs({
        { method = 'wsAuthorizedRcon' }, { actorDiscordID = '' }, { actorDiscordID = 123 },
        { actorDiscordID = '123456789012345678901' }, { actorDiscordID = 'admin' },
        { actorDiscordID = '123\n456' }, { requestID = 'bad' }, { command = '' }, { command = ' \t ' },
        { command = string.rep('x', 8193) }, { command = string.rep('é', 4097) },
        { command = 'status\nquit' }, { command = 'status\rquit' }, { command = 'status\0quit' },
        { expiresAt = '1700000005000' }, { expiresAt = 0 / 0 }, { expiresAt = os.time() * 1000 + 5000.5 },
        { steamID = '76561198000000001' }, { extra = true },
    }) do
        assert(gmInte.wsPanelRcon(panelRconPacket(changes)) == false)
    end
    assert(gmInte.wsPanelRcon(false) == false and gmInte.wsPanelRcon({}) == false)
    for _, deadline in ipairs({ os.time() * 1000, os.time() * 1000 + 500, os.time() * 1000 + 10001, math.huge }) do
        local ok, code = gmInte.wsPanelRcon(panelRconPacket({ expiresAt = deadline }))
        assert(ok == false and code == 'expired')
    end
    assert(observations.commands == nil)
    assert(gmInte.validatePanelRconCommand(panelRconPacket({ actorDiscordID = '1', command = string.rep('é', 4096) })))
    assert(gmInte.validatePanelRconCommand(panelRconPacket({ actorDiscordID = '12345678901234567890', command = 'status; echo accepted' })))
end)

test('panel RCON reserves UUIDs across actors, bodies, deadlines and both command methods', function()
    local packet = panelRconPacket()
    assert(gmInte.wsPanelRcon(packet) == true)
    for _, changes in ipairs({ { actorDiscordID = '999' }, { command = 'quit' }, { expiresAt = packet.expiresAt + 1 } }) do
        local ok, code = gmInte.wsPanelRcon(panelRconPacket(changes))
        assert(ok == false and code == 'execution_failed')
    end
    onlinePlayer('superadmin')
    assert(gmInte.wsAuthorizedRcon(rconPacket()) == false)
    assert(observations.commands == 1)
    reset()
    onlinePlayer('superadmin')
    assert(gmInte.wsAuthorizedRcon(rconPacket()) == true)
    assert(gmInte.wsPanelRcon(panelRconPacket()) == false)
    assert(observations.commands == 1)
end)

test('panel RCON shares the 128-request bound and remembers a failed console submission', function()
    for index = 1, 128 do
        assert(gmInte.wsPanelRcon(panelRconPacket({ requestID = string.format('%08x-ff6f-4ed4-b2b9-f4b722840f04', index) })) == true)
    end
    assert(gmInte.wsPanelRcon(panelRconPacket()) == false and observations.commands == 128)
    reset({ consoleFailure = true })
    local ok, code = gmInte.wsPanelRcon(panelRconPacket())
    assert(ok == false and code == 'execution_failed')
    assert(gmInte.wsPanelRcon(panelRconPacket()) == false)
    assert(observations.consoleCalls == 1)
end)

test('RCON checks current configured ranks and acknowledges execution only once', function()
    gmInte.config.adminRank = { owner = true }
    onlinePlayer('owner')
    gmInte.setupWebSocket()
    local socket = sockets[1]
    ready(socket)
    local packet = rconPacket()
    message(socket, packet)
    local ack = util.JSONToTable(socket.writes[#socket.writes])
    assert(ack.action == 'addon.command-result' and ack.id == packet.requestID and ack.ok == true and ack.code == 'executed')
    assert(observations.commands == 1 and observations.command == 'status\n')
    message(socket, packet)
    assert(observations.commands == 1)
    message(socket, rconPacket({ command = 'quit' }))
    assert(observations.commands == 1)
    assert(util.JSONToTable(socket.writes[#socket.writes]).ok == false)
end)

test('RCON refuses offline, demoted and no-longer-configured administrators', function()
    assert(gmInte.wsAuthorizedRcon(rconPacket()) == false)
    onlinePlayer('superadmin')
    gmInte.config.adminRank = { owner = true }
    local ok, code = gmInte.wsAuthorizedRcon(rconPacket({ requestID = '4a918b48-ff6f-4ed4-b2b9-f4b722840f04' }))
    assert(ok == false and code == 'permission_denied' and observations.commands == nil)
    onlinePlayer('owner')
    observations.player.group = 'user'
    assert(gmInte.wsAuthorizedRcon(rconPacket({ requestID = '5a918b48-ff6f-4ed4-b2b9-f4b722840f04' })) == false)
end)

test('RCON rejects expired, malformed, oversized and legacy packets', function()
    onlinePlayer('superadmin')
    for _, changes in ipairs({ { command = '' }, { command = string.rep('x', 8193) }, { command = 'status\nquit' }, { command = 'status\0quit' }, { steamID = 'bad' }, { requestID = 'bad' }, { extra = true } }) do
        assert(gmInte.wsAuthorizedRcon(rconPacket(changes)) == false)
    end
    assert(gmInte.wsAuthorizedRcon({ method = 'wsAuthorizedRcon', command = 'status', steamID = '76561198000000001' }) == false)
    local ok, code = gmInte.wsAuthorizedRcon(rconPacket({ expiresAt = os.time() * 1000 }))
    assert(ok == false and code == 'expired')
    assert(gmInte.wsAuthorizedRcon(rconPacket({ expiresAt = os.time() * 1000 + 500 })) == false)
    assert(gmInte.wsAuthorizedRcon(rconPacket({ expiresAt = os.time() * 1000 + 20000 })) == false)
    assert(observations.commands == nil)
end)

test('RCON acknowledges execution failures without retrying the console effect', function()
    reset({ consoleFailure = true })
    onlinePlayer('superadmin')
    local ok, code = gmInte.wsAuthorizedRcon(rconPacket())
    assert(ok == false and code == 'execution_failed')
    assert(gmInte.wsAuthorizedRcon(rconPacket()) == false)
end)

test('resolves every batched log endpoint to the authenticated server', function()
    gmInte.setupWebSocket()
    local socket = sockets[1]
    ready(socket)
    gmInte.api.postLog('/servers/:serverID/players/76561198000000001/spawn', { player = {} })
    timers['gmInte:API:FlushLogs']()
    local request = util.JSONToTable(socket.writes[1])
    assert(request.endpoint == '/servers/server-id/logs')
    assert(request.body[1].endpoint == '/servers/server-id/players/76561198000000001/spawn')
end)

test('keeps exact string IDs, validates remote settings and excludes secrets from sync', function()
    originalLoad('lua/gmod_integration/core/config/sv_settings.lua')
    assert(gmInte.saveSetting('id', '1051881514020917408'))
    assert(gmInte.config.id == '1051881514020917408')
    assert(gmInte.validateRemoteSetting('ig_syncBan', 'false'))
    assert(not gmInte.validateRemoteSetting('ig_token', 'other-secret'))
    assert(not gmInte.validateRemoteSetting('ig_verifyOnReadyKickTime', -1))
    assert(not gmInte.validateRemoteSetting('ig_adminRank', { superadmin = 'yes' }))
    assert(not gmInte.validateRemoteSetting('ig_adminRank', { superadmin = false }))
    local validRanks, normalizedRanks = gmInte.validateRemoteSetting('ig_adminRank', { superadmin = true, oldadmin = false })
    assert(validRanks and normalizedRanks.superadmin == true and normalizedRanks.oldadmin == nil)
    assert(not gmInte.validateRemoteSetting('ig_supportLink', 'javascript:alert(1)'))
    assert(gmInte.validateRemoteSetting('ig_supportLink', 'https://example.com/support'))
    assert(gmInte.validateRemoteSetting('ig_verifyOnReadyKickTime', 200000))
    ready(sockets[#sockets])
    message(sockets[#sockets], { action = 'addon.response', id = util.JSONToTable(sockets[#sockets].writes[1]).id, status = 200, body = { settings = { ig_syncBan = 'false' } } })
    assert(gmInte.config.syncBan == false)
    assert(gmInte.saveSetting('debug', true))
    local socket = sockets[#sockets]
    local request = util.JSONToTable(socket.writes[#socket.writes])
    assert(request.endpoint == '/servers/1051881514020917408/config')
    assert(request.body.debug == true and request.body.token == nil and request.body.id == nil and request.body.websocketFQDN == nil)
    assert(observations.persisted.token == 'secret-token')
end)

test('only admins can issue an in-game connection test', function()
    originalLoad('lua/gmod_integration/core/config/sv_settings.lua')
    local ordinary = { IsPlayer = function() return true end, gmIntIsAdmin = function() return false end }
    gmInte.testConnection(ordinary)
    assert(#sockets == 0 and observations.net == nil)
end)

test('syncs offline local changes before reading remote configuration', function()
    originalLoad('lua/gmod_integration/core/config/sv_settings.lua')
    assert(gmInte.saveSetting('debug', true))
    assert(#sockets == 0)
    gmInte.setupWebSocket()
    local socket = sockets[1]
    ready(socket)
    assert(#socket.writes == 1)
    local request = util.JSONToTable(socket.writes[1])
    assert(request.method == 'POST' and request.body.debug == true)
end)

test('ignores stale config reads and serializes successive local snapshots', function()
    originalLoad('lua/gmod_integration/core/config/sv_settings.lua')
    gmInte.setupWebSocket()
    local socket = sockets[1]
    ready(socket)
    local read = util.JSONToTable(socket.writes[1])
    assert(gmInte.saveSetting('debug', true))
    assert(gmInte.saveSetting('maintenance', true))
    assert(#socket.writes == 2)
    message(socket, { action = 'addon.response', id = read.id, status = 200, body = { settings = { ig_debug = false } } })
    assert(gmInte.config.debug == true)
    local firstSave = util.JSONToTable(socket.writes[2])
    message(socket, { action = 'addon.response', id = firstSave.id, status = 200, body = {} })
    assert(#socket.writes == 3)
    local finalSave = util.JSONToTable(socket.writes[3])
    assert(finalSave.body.debug == true and finalSave.body.maintenance == true)
end)

print('transport mocked tests passed: ' .. passed)
