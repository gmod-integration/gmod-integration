local CHUNK_BYTES = 30000
local MAX_ENCODED_BYTES = 8 * 1024 * 1024
local MAX_JSON_BYTES = 10 * 1024 * 1024
local pending = {}
local sequence = 0

local function finish(id, status, body)
    local request = pending[id]
    if not request then return end
    pending[id] = nil
    timer.Remove("gmInte:API:ClientUpload:" .. id)
    timer.Remove("gmInte:API:ClientTimeout:" .. id)
    local callback = request.failed
    if status >= 200 and status < 300 then callback = request.success end
    if isfunction(callback) then
        local ok = pcall(callback, status, body or {})
        if not ok then gmInte.logError("Client API callback failed", true) end
    end
end

function gmInte.cancelClientAPI(id)
    if not pending[id] then return end
    gmInte.SendNet("apiRelayCancel", { id = id })
    finish(id, 499, { error = "request_cancelled" })
end

function gmInte.sendClientAPI(params)
    local fail = params.failed or function() end
    if not IsValid(LocalPlayer()) then
        fail(503, { error = "player_unavailable" })
        return false
    end
    local kind = isstring(params.endpoint) and params.endpoint:match("^/clients/[^/]+/servers/[^/]+/(%a+)$")
    if params.method ~= "POST" or (kind ~= "screenshots" and kind ~= "bugs" and kind ~= "errors") then
        fail(403, { error = "client_operation_forbidden" })
        return false
    end
    if next(pending) then
        fail(429, { error = "client_request_pending" })
        return false
    end
    local ok, json = pcall(util.TableToJSON, params.body or {})
    if not ok or not isstring(json) or #json > MAX_JSON_BYTES then
        fail(413, { error = "payload_too_large" })
        return false
    end
    local compressed = util.Compress(json)
    if not isstring(compressed) or #compressed > MAX_ENCODED_BYTES * 0.75 then
        fail(413, { error = "payload_too_large" })
        return false
    end
    local encoded = util.Base64Encode(compressed, true)
    if not isstring(encoded) or #encoded == 0 or #encoded > MAX_ENCODED_BYTES then
        fail(413, { error = "payload_too_large" })
        return false
    end
    sequence = sequence + 1
    local id = tostring(SysTime()) .. "-" .. sequence
    local count = math.ceil(#encoded / CHUNK_BYTES)
    local part = 0
    pending[id] = { success = params.success, failed = params.failed }
    timer.Create("gmInte:API:ClientTimeout:" .. id, 90, 1, function()
        if pending[id] then
            gmInte.SendNet("apiRelayCancel", { id = id })
            finish(id, 504, { error = "request_timeout" })
        end
    end)
    timer.Create("gmInte:API:ClientUpload:" .. id, 0.05, count, function()
        if not pending[id] then return end
        part = part + 1
        local sent, accepted = pcall(gmInte.SendNet, "apiRelayChunk", {
            id = id,
            kind = kind,
            part = part,
            count = count,
            total = #encoded,
            rawBytes = #json,
            content = encoded:sub((part - 1) * CHUNK_BYTES + 1, part * CHUNK_BYTES)
        })
        if not sent or accepted == false then finish(id, 503, { error = "relay_unavailable" }) end
    end)
    return id
end

function gmInte.receiveClientAPIResponse(data)
    if not istable(data) or not isstring(data.id) or not isnumber(data.status) then return end
    if data.status < 100 or data.status > 599 or data.status % 1 ~= 0 then return end
    finish(data.id, data.status, istable(data.body) and data.body or {})
end

hook.Add("ShutDown", "gmInte:API:ClientShutdown", function()
    local ids = table.GetKeys(pending)
    for _, id in ipairs(ids) do finish(id, 503, { error = "client_shutdown" }) end
end)
