local MAX_PACKET_BYTES = 12 * 1024 * 1024
local MAX_REQUESTS = 128
local MAX_BUFFER_BYTES = 24 * 1024 * 1024
local MAX_IN_FLIGHT = 4
local REQUEST_TIMEOUT = 30
local pending = {}
local queued = {}
local bufferedBytes = 0
local pendingBytes = 0
local pendingCount = 0
local requestCount = 0
local sequence = 0
local generation = 0
local retryAt = 0
local retryDelay = 1
local openingAt = nil
local stopped = false
local draining = false

local function resetConsoleStream()
    gmInte.config.consoleLiveExporter = false
    gmInte.enableConsoleLiveExporter = false
    if isfunction(gmInte.stopConsoleStream) then gmInte.stopConsoleStream() end
end
resetConsoleStream()

local moduleOK = pcall(require, "gwsockets")
moduleOK = moduleOK && istable(GWSockets) && isfunction(GWSockets.createWebSocket)

function gmInte.hasWebsocketModule()
    return moduleOK == true && istable(GWSockets) && isfunction(GWSockets.createWebSocket)
end

function gmInte.logWebsocketRequirement()
    if gmInte.hasWebsocketModule() then return false end
    gmInte.logError(gmInte.getTranslation("admin.gwsockets_required", "GWSockets is missing or could not be loaded. This library is mandatory: all connected Gmod Integration features are unavailable without it."))
    gmInte.logHint(gmInte.getTranslation("admin.gwsockets_installation", "Install the GWSockets server binary matching the server's operating system and architecture in garrysmod/lua/bin, then fully stop and restart the server. A map change is not enough."))
    gmInte.logHint("https://docs.gmod-integration.com/getting-started/installation#dll")
    return true
end

if !moduleOK then timer.Simple(1, gmInte.logWebsocketRequirement) end

local function call(callback, code, body)
    if !isfunction(callback) then return end
    local ok = pcall(callback, code, body)
    if !ok then gmInte.logError("WebSocket callback failed", true) end
end

local function release(request)
    if request.sentAt != nil then
        pendingBytes = math.max(0, pendingBytes - #request.packet)
        pendingCount = math.max(0, pendingCount - 1)
        request.sentAt = nil
    end
    bufferedBytes = math.max(0, bufferedBytes - #request.packet)
    requestCount = math.max(0, requestCount - 1)
end

local function failPending(reason)
    local previous = pending
    pending = {}
    for _, request in pairs(previous) do
        release(request)
        call(request.failed, 503, { error = reason, delivery = "uncertain" })
    end
end

local function clearQueue(reason)
    local previous = queued
    queued = {}
    for _, request in ipairs(previous) do
        release(request)
        call(request.failed, 503, { error = reason, delivery = "not_sent" })
    end
end

local function connected()
    return gmInte.aprovedCredentials && gmInte.websocket && gmInte.websocket:isConnected()
end

local function transmit(request)
    if !connected() || pendingCount >= MAX_IN_FLIGHT || pendingBytes + #request.packet > MAX_BUFFER_BYTES then return false end
    pending[request.id] = request
    request.sentAt = SysTime()
    pendingCount = pendingCount + 1
    pendingBytes = pendingBytes + #request.packet
    local ok = pcall(function() gmInte.websocket:write(request.packet) end)
    if !ok then
        pending[request.id] = nil
        release(request)
        gmInte.aprovedCredentials = false
        resetConsoleStream()
        pcall(function() gmInte.websocket:close() end)
        call(request.failed, 503, { error = "write_failed", delivery = "uncertain" })
    end
    return true
end

local function drainQueue()
    if draining then return end
    draining = true
    while #queued > 0 do
        local request = queued[1]
        if SysTime() - request.createdAt >= REQUEST_TIMEOUT then
            table.remove(queued, 1)
            release(request)
            call(request.failed, 504, { error = "queue_timeout", delivery = "not_sent" })
        elseif !connected() || pendingCount >= MAX_IN_FLIGHT || pendingBytes + #request.packet > MAX_BUFFER_BYTES then
            break
        else
            table.remove(queued, 1)
            transmit(request)
        end
    end
    draining = false
end

function gmInte.websocketRequest(params)
    if !gmInte.hasWebsocketModule() then
        call(params.failed, 503, { error = "gwsockets_required" })
        return false
    end
    if !isstring(gmInte.config.id) || gmInte.config.id == "" || !isstring(gmInte.config.token) || gmInte.config.token == "" then
        call(params.failed, 401, { error = "missing_credentials" })
        return false
    end
    sequence = sequence + 1
    local id = tostring(generation) .. ":" .. tostring(sequence) .. ":" .. tostring(SysTime())
    local ok, packet = pcall(util.TableToJSON, {
        action = "addon.request", id = id, method = params.method, endpoint = params.endpoint, body = params.body,
    })
    if !ok || !isstring(packet) || #packet > MAX_PACKET_BYTES then
        call(params.failed, 413, { error = "payload_too_large" })
        return false
    end
    if requestCount >= MAX_REQUESTS || bufferedBytes + #packet > MAX_BUFFER_BYTES then
        call(params.failed, 429, { error = "request_buffer_full" })
        return false
    end
    local request = { id = id, packet = packet, success = params.success, failed = params.failed, createdAt = SysTime() }
    requestCount = requestCount + 1
    bufferedBytes = bufferedBytes + #packet
    table.insert(queued, request)
    drainQueue()
    return id
end

local function shortString(value, maximum, allowEmpty)
    return isstring(value) && #value <= maximum && (allowEmpty || #value > 0) && !string.find(value, "\0", 1, true)
end
local function steamID64(value)
    return isstring(value) && #value == 17 && string.match(value, "^%d+$") != nil
end
local function commandTarget(data)
    return steamID64(data.steam) && (data.reason == nil || shortString(data.reason, 2048, true))
end

-- Only these existing privileged entry points may be called by the authenticated service.
local commands = {
    wsConsoleStream = {
        validate = function(data) return isfunction(gmInte.validateConsoleStream) && gmInte.validateConsoleStream(data) end,
        run = function(data) return gmInte.wsConsoleStream(data) end,
    },
    wsRefreshPlayerAccess = {
        validate = function(data)
            for key in pairs(data) do
                if key != "method" && key != "steamID" then return false end
            end
            return data.steamID == nil || steamID64(data.steamID)
        end,
        run = function(data) gmInte.wsRefreshPlayerAccess(data) end,
    },
    wsEditSetting = {
        validate = function(data)
            return shortString(data.setting, 96) && isfunction(gmInte.validateRemoteSetting) && gmInte.validateRemoteSetting(data.setting, data.value)
        end,
        run = function(data) gmInte.wsEditSetting(data) end,
    },
    wsPlayerSay = {
        validate = function(data) return shortString(data.name, 128) && shortString(data.content, 4000, true) end,
        run = function(data) gmInte.wsPlayerSay(data) end,
    },
    wsSyncBan = { validate = commandTarget, run = function(data) gmInte.wsSyncBan(data) end },
    wsSyncKick = { validate = commandTarget, run = function(data) gmInte.wsSyncKick(data) end },
    wsSyncName = {
        validate = function(data) return steamID64(data.steamID64) && shortString(data.name, 128) end,
        run = function(data) gmInte.wsSyncName(data) end,
    },
    wsPlayerUpdateGroup = {
        validate = function(data) return steamID64(data.steamID64) && shortString(data.group, 64) && isbool(data.add) end,
        run = function(data) gmInte.wsPlayerUpdateGroup(data) end,
    },
    wsAuthorizedRcon = {
        validate = function(data) return isfunction(gmInte.validateRconCommand) && gmInte.validateRconCommand(data) end,
        run = function(data) return gmInte.wsAuthorizedRcon(data) end,
    },
    wsPanelRcon = {
        validate = function(data) return isfunction(gmInte.validatePanelRconCommand) && gmInte.validatePanelRconCommand(data) end,
        run = function(data) return gmInte.wsPanelRcon(data) end,
    },
    wsRunLua = {
        validate = function(data) return shortString(data.data, 128 * 1024) && shortString(data.steamID, 128) end,
        run = function(data) gmInte.wsRunLua(data) end,
    },
    wsServerRunLua = {
        validate = function(data) return shortString(data.data, 128 * 1024) end,
        run = function(data) gmInte.wsServerRunLua(data) end,
    },
}

local function onRemoteCommand(data)
    local command = commands[data.method]
    if !command || !command.validate(data) then
        gmInte.logWarning("Rejected an unsupported or malformed WebSocket command", true)
        return
    end
    local ok, executed, code = pcall(command.run, data)
    if !ok then gmInte.logError("WebSocket command failed", true) end
    if data.method == "wsAuthorizedRcon" || data.method == "wsPanelRcon" then
        local result = { action = "addon.command-result", id = data.requestID, method = data.method, ok = ok && executed == true, code = ok && code || "execution_failed" }
        pcall(function() gmInte.websocket:write(util.TableToJSON(result)) end)
    end
end

local function scheduleRetry()
    retryAt = SysTime() + retryDelay + math.Rand(0, retryDelay * 0.2)
    retryDelay = math.min(60, retryDelay * 2)
end

function gmInte.setupWebSocket()
    resetConsoleStream()
    if stopped || !gmInte.hasWebsocketModule() then return false end
    generation = generation + 1
    local current = generation
    local oldSocket = gmInte.websocket
    gmInte.websocket = nil
    gmInte.aprovedCredentials = false
    openingAt = SysTime()
    if oldSocket then pcall(function() oldSocket:close() end) end
    failPending("connection_replaced")
    if !isstring(gmInte.config.id) || gmInte.config.id == "" || !isstring(gmInte.config.token) || gmInte.config.token == "" then openingAt = nil return false end
    if !isstring(gmInte.config.websocketFQDN) || !string.match(gmInte.config.websocketFQDN, "^[%w%.%-%:%[%]]+$") then openingAt = nil return false end
    local host = gmInte.config.websocketFQDN
    local scheme = gmInte.isPrivateIP(string.match(host, "^([^:]+)") || host) && "ws" || "wss"
    local ok, socket = pcall(GWSockets.createWebSocket, scheme .. "://" .. host)
    if !ok || !socket then openingAt = nil scheduleRetry() return false end
    gmInte.websocket = socket
    socket:setHeader("id", gmInte.config.id)
    socket:setHeader("token", gmInte.config.token)
    socket:setHeader("gmod-integrations-version", gmInte.version)

    function socket:onConnected()
        if current != generation then return end
        -- TCP open alone does not confirm authentication or protocol compatibility.
        gmInte.log("WebSocket transport connected", true)
    end

    function socket:onMessage(text)
        if current != generation || !isstring(text) || #text > MAX_PACKET_BYTES then return end
        local parsed, data = pcall(util.JSONToTable, text)
        if !parsed || !istable(data) then return end
        if data.action == "addon.ready" && data.protocol == 1 then
            if gmInte.aprovedCredentials then return end
            gmInte.aprovedCredentials = true
            openingAt = nil
            retryDelay = 1
            gmInte.log("Connected to Gmod Integration using WebSocket")
            hook.Run("GmodIntegration:Websocket:Ready")
            drainQueue()
        elseif data.action == "addon.response" && shortString(data.id, 96) && isnumber(data.status) && data.status >= 100 && data.status <= 599 && data.status % 1 == 0 then
            local request = pending[data.id]
            if !request then return end
            pending[data.id] = nil
            release(request)
            if data.status >= 200 && data.status < 300 then
                call(request.success, data.status, data.body)
            else
                call(request.failed, data.status, data.body)
            end
            drainQueue()
        elseif gmInte.aprovedCredentials && isstring(data.method) then
            onRemoteCommand(data)
        end
    end

    function socket:onDisconnected()
        if current != generation then return end
        resetConsoleStream()
        gmInte.aprovedCredentials = false
        openingAt = nil
        failPending("connection_lost")
        scheduleRetry()
    end

    function socket:onError()
        if current != generation then return end
        resetConsoleStream()
        gmInte.logError("WebSocket connection failed", true)
        gmInte.aprovedCredentials = false
        openingAt = nil
        failPending("connection_error")
        scheduleRetry()
    end

    function socket:send(method, data, callback)
        -- Compatibility for the existing console exporter; API mutations use correlated requests.
        if method == "console_live_exporter" && gmInte.config.consoleLiveExporter == true && gmInte.enableConsoleLiveExporter == true && istable(data) && shortString(data.data, 32 * 1024, true) && connected() then
            local sent = pcall(function() self:write(util.TableToJSON({ action = method, data = data })) end)
            if isfunction(callback) then pcall(callback, sent, sent && {} || "write_failed") end
            return sent
        end
        if isfunction(callback) then pcall(callback, false, "unsupported_method") end
        return false
    end

    local opened = pcall(function() socket:open() end)
    if !opened then openingAt = nil scheduleRetry() end
    return opened
end

hook.Add("GmodIntegration:Websocket:Restart", "gmInte:WebSocket:Restart", function()
    resetConsoleStream()
    failPending("credentials_changed")
    clearQueue("credentials_changed")
    retryDelay = 1
    retryAt = 0
    gmInte.setupWebSocket()
end)

hook.Add("InitPostEntity", "gmInte:ServerReady:WebSocket", function()
    timer.Simple(1, function() if !connected() && !openingAt then gmInte.setupWebSocket() end end)
end)

hook.Add("ShutDown", "gmInte:WebSocket:Shutdown", function()
    resetConsoleStream()
    stopped = true
    clearQueue("server_stopping")
    -- Let lifecycle hooks write their final packet before closing the transport.
end)

timer.Create("gmInte:WebSocket:CheckConnection", 1, 0, function()
    local now = SysTime()
    for id, request in pairs(pending) do
        if now - request.sentAt >= REQUEST_TIMEOUT then
            pending[id] = nil
            release(request)
            call(request.failed, 504, { error = "response_timeout", delivery = "uncertain" })
        end
    end
    drainQueue()
    if openingAt && now - openingAt >= 15 then
        resetConsoleStream()
        openingAt = nil
        generation = generation + 1
        if gmInte.websocket then pcall(function() gmInte.websocket:close() end) end
        gmInte.aprovedCredentials = false
        failPending("handshake_timeout")
        scheduleRetry()
    end
    if !stopped && !connected() && !openingAt && now >= retryAt then gmInte.setupWebSocket() end
end)
