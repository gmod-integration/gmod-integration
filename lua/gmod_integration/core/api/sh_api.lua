gmInte.api = gmInte.api || {}

local function finish(callback, code, body)
    if !isfunction(callback) then return end
    local ok = pcall(callback, code, body)
    if !ok then gmInte.logError("API callback failed", true) end
end

function gmInte.api.requestAPI(params)
    if !istable(params) then return false end
    local endpoint = params.endpoint
    local method = params.method || "GET"
    if !isstring(endpoint) || #endpoint > 256 || string.sub(endpoint, 1, 1) != "/" ||
        (method != "GET" && method != "POST") then
        finish(params.failed, 400, { error = "invalid_request" })
        return false
    end
    endpoint = string.gsub(endpoint, ":serverID", tostring(gmInte.config.id || ""))
    if CLIENT then
        if !IsValid(LocalPlayer()) then
            finish(params.failed, 503, { error = "player_unavailable" })
            return false
        end
        endpoint = string.gsub(endpoint, ":steamID64", LocalPlayer():SteamID64())
    end
    local request = {
        endpoint = endpoint,
        method = method,
        body = params.body,
        success = params.success,
        failed = params.failed,
    }
    if CLIENT && isfunction(gmInte.sendClientAPI) then return gmInte.sendClientAPI(request) end
    if SERVER && isfunction(gmInte.websocketRequest) then return gmInte.websocketRequest(request) end
    finish(params.failed, 503, { error = "websocket_unavailable" })
    return false
end

function gmInte.api.get(endpoint, onSuccess, onFailed)
    return gmInte.api.requestAPI({ endpoint = endpoint, method = "GET", success = onSuccess, failed = onFailed })
end

function gmInte.api.post(endpoint, data, onSuccess, onFailed)
    return gmInte.api.requestAPI({ endpoint = endpoint, method = "POST", body = data, success = onSuccess, failed = onFailed })
end

local nextLogPacket = {}
local function flushLogs()
    if #nextLogPacket == 0 then return end
    local packet = nextLogPacket
    nextLogPacket = {}
    gmInte.api.post("/servers/:serverID/logs", packet, nil, function()
        -- Sent events are never blindly replayed: their delivery may already have succeeded.
        gmInte.logWarning("A telemetry batch could not be confirmed", true)
    end)
end

function gmInte.api.postLog(endpoint, data)
    if !isstring(endpoint) || !istable(data) then return end
    endpoint = string.gsub(endpoint, ":serverID", tostring(gmInte.config.id || ""))
    table.insert(nextLogPacket, { endpoint = endpoint, data = data })
    if #nextLogPacket >= 30 then flushLogs() end
end

hook.Add("ShutDown", "gmInte:Server:ShutDown:FlushLogs", flushLogs)
hook.Add("GMI:SaveBeforeCrash", "gmInte:Server:BeforeCrash:SavePlayers", flushLogs)
timer.Create("gmInte:API:FlushLogs", 3, 0, flushLogs)
