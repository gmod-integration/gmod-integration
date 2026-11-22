local CHUNK_BYTES = 30000
local MAX_ENCODED_BYTES = 8 * 1024 * 1024
local MAX_JSON_BYTES = 10 * 1024 * 1024
local MAX_RESERVED_BYTES = 32 * 1024 * 1024
local reservedBytes = 0
local active = {}
local rates = {}
local importance = { critical = true, high = true, medium = true, low = true, trivial = true }

local function finite(value, minimum, maximum)
    return isnumber(value) and value == value and value >= minimum and value <= maximum
end

local function boundedString(value, maximum, required)
    return isstring(value) and #value <= maximum and (not required or #value > 0)
end

local function release(ply)
    local transfer = active[ply]
    if not transfer then return end
    reservedBytes = math.max(0, reservedBytes - transfer.reservedBytes)
    active[ply] = nil
end

local function respond(ply, id, status, body)
    if not IsValid(ply) then return end
    -- Client tools only need the outcome; do not echo stored reports, images or server internals.
    local result = status >= 200 and status < 300 and { success = true } or {
        error = istable(body) and boundedString(body.error, 256, true) and body.error or "request_failed"
    }
    if result.success and istable(body) and body.saved == true and isbool(body.discordDelivered) then
        result.saved = true
        result.discordDelivered = body.discordDelivered
        if body.discordDelivered == false and (body.delivery == "not_configured" or body.delivery == "unavailable") then
            result.delivery = body.delivery
        end
    end
    gmInte.SendNet("apiRelayResponse", { id = id, status = status, body = result }, ply)
end

local function reject(ply, id, status, error)
    release(ply)
    respond(ply, id, status, { error = error })
end

local function permitStart(ply, kind)
    local now = CurTime()
    local rate = rates[ply] or { minute = now, count = 0, nextUpload = 0, nextError = 0, nextStart = 0 }
    rates[ply] = rate
    if now < rate.nextStart then return false end
    rate.nextStart = now + 0.25
    if now - rate.minute >= 60 then rate.minute = now; rate.count = 0 end
    if rate.count >= 10 then return false end
    if kind == "errors" then
        if now < rate.nextError then return false end
        rate.nextError = now + 1
    else
        if now < rate.nextUpload then return false end
        rate.nextUpload = now + 10
    end
    rate.count = rate.count + 1
    return true
end

local function validCapture(data)
    return istable(data) and (data.format == "jpeg" or data.format == "png") and
        finite(data.w, 1, 16384) and finite(data.h, 1, 16384) and
        finite(data.x, 0, 16384) and finite(data.y, 0, 16384) and finite(data.quality, 0, 100)
end

local function cleanImage(data)
    if not istable(data) or not boundedString(data.screenshot, 9 * 1024 * 1024, true) then return end
    if #data.screenshot % 4 ~= 0 or not data.screenshot:match("^[%w+/]*=?=?$") or not validCapture(data.captureData) then return end
    local capture = data.captureData
    return {
        screenshot = data.screenshot,
        size = math.ceil(#data.screenshot / 1024) .. "KB",
        captureData = { format = capture.format, w = capture.w, h = capture.h, x = capture.x, y = capture.y, quality = capture.quality }
    }
end

local function validStack(value, depth, budget)
    if depth > 6 then return false end
    budget.count = budget.count + 1
    if budget.count > 2000 then return false end
    if isstring(value) then return #value <= 8192 end
    if isnumber(value) then return finite(value, -1000000000, 1000000000) end
    if isbool(value) then return true end
    if not istable(value) then return false end
    for key, child in pairs(value) do
        if not (boundedString(key, 128, true) or finite(key, 1, 2000)) or not validStack(child, depth + 1, budget) then return false end
    end
    return true
end

local function cleanBody(ply, kind, body)
    if not istable(body) then return end
    if kind == "errors" then
        if not boundedString(body.error, 8192, true) or not finite(body.uptime, 0, 1000000000) or
            not finite(body.count, 1, 1000000) or not validStack(body.stack, 0, { count = 0 }) then return end
        if body.name ~= nil and not boundedString(body.name, 256, false) then return end
        if body.id ~= nil and not boundedString(body.id, 64, false) then return end
        local stackJSON = util.TableToJSON({ stack = body.stack })
        if not stackJSON or #stackJSON > 65536 then return end
        return {
            error = body.error, stack = body.stack, name = body.name, id = body.id,
            realm = "client", uptime = body.uptime, count = body.count, identifier = ply:SteamID64()
        }
    end
    local player = gmInte.getPlayerFormat(ply)
    if not player then return end
    if kind == "screenshots" then
        local image = cleanImage(body)
        if not image or (body.title ~= nil and not boundedString(body.title, 256, false)) then return end
        image.player = player
        image.title = body.title or ""
        return image
    end
    if not boundedString(body.description, 8000, true) or not boundedString(body.steps, 8000, true) or
        not boundedString(body.expected, 8000, true) or not boundedString(body.actual, 8000, true) or
        not isstring(body.importance) or not importance[body.importance] then return end
    local image
    if istable(body.screenshot) and body.screenshot.screenshot ~= nil then
        image = cleanImage(body.screenshot)
        if not image then return end
    elseif body.screenshot ~= nil and not istable(body.screenshot) then
        return
    end
    return {
        player = player, screenshot = image, description = body.description, importance = body.importance,
        steps = body.steps, expected = body.expected, actual = body.actual
    }
end

function gmInte.receiveClientAPIChunk(ply, data)
    if not IsValid(ply) or not ply:IsPlayer() or not istable(data) then return end
    if not boundedString(data.id, 96, true) or not data.id:match("^[%w%.%-]+$") then return end
    if data.kind ~= "screenshots" and data.kind ~= "bugs" and data.kind ~= "errors" then return end
    if not finite(data.part, 1, 280) or data.part % 1 ~= 0 or not finite(data.count, 1, 280) or data.count % 1 ~= 0 or
        not finite(data.total, 1, MAX_ENCODED_BYTES) or data.total % 1 ~= 0 or
        not finite(data.rawBytes, 2, MAX_JSON_BYTES) or data.rawBytes % 1 ~= 0 or
        not boundedString(data.content, CHUNK_BYTES, true) or not data.content:match("^[%w+/=]+$") then
        if active[ply] and active[ply].id == data.id then reject(ply, data.id, 400, "invalid_transfer") end
        return
    end
    local expectedCount = math.ceil(data.total / CHUNK_BYTES)
    local expectedLength = data.part == data.count and data.total - (data.count - 1) * CHUNK_BYTES or CHUNK_BYTES
    if data.count ~= expectedCount or data.part > data.count or #data.content ~= expectedLength then
        if active[ply] and active[ply].id == data.id then reject(ply, data.id, 400, "invalid_transfer") end
        return
    end
    local transfer = active[ply]
    if not transfer then
        if data.part ~= 1 then return end
        if not permitStart(ply, data.kind) then respond(ply, data.id, 429, { error = "too_many_requests" }); return end
        local reservation = data.total + data.rawBytes
        if reservedBytes + reservation > MAX_RESERVED_BYTES then respond(ply, data.id, 503, { error = "relay_busy" }); return end
        transfer = {
            id = data.id, kind = data.kind, total = data.total, rawBytes = data.rawBytes, count = data.count,
            nextPart = 1, parts = {}, expires = CurTime() + 60, reservedBytes = reservation
        }
        active[ply] = transfer
        reservedBytes = reservedBytes + reservation
    elseif transfer.id ~= data.id then
        return
    end
    if transfer.forwarding then return end
    if transfer.nextPart ~= data.part or transfer.kind ~= data.kind or transfer.total ~= data.total or
        transfer.count ~= data.count or transfer.rawBytes ~= data.rawBytes then
        reject(ply, data.id, 400, "invalid_transfer")
        return
    end
    transfer.parts[data.part] = data.content
    transfer.nextPart = transfer.nextPart + 1
    if data.part ~= data.count then return end
    local encoded = table.concat(transfer.parts)
    transfer.parts = nil
    local decoded = util.Base64Decode(encoded)
    local ok, json = pcall(util.Decompress, decoded or "", MAX_JSON_BYTES)
    if not ok or not isstring(json) or #json ~= transfer.rawBytes then
        reject(ply, data.id, 400, "invalid_transfer")
        return
    end
    local suppliedBody = gmInte.decodeBoundedNetJSON(json, MAX_JSON_BYTES)
    local body = suppliedBody and cleanBody(ply, transfer.kind, suppliedBody)
    if not body then reject(ply, data.id, 400, "invalid_payload"); return end
    if not gmInte.config.id or gmInte.config.id == "" then reject(ply, data.id, 503, "server_unconfigured"); return end
    transfer.forwarding = true
    transfer.expires = CurTime() + 65
    local function complete(status, result)
        if active[ply] ~= transfer then return end
        release(ply)
        respond(ply, data.id, status, result)
    end
    gmInte.api.requestAPI({
        method = "POST",
        endpoint = "/clients/" .. ply:SteamID64() .. "/servers/" .. gmInte.config.id .. "/" .. transfer.kind,
        body = body,
        success = complete,
        failed = complete
    })
end

function gmInte.cancelClientAPIRelay(ply, data)
    if not istable(data) or not active[ply] or active[ply].id ~= data.id or active[ply].forwarding then return end
    release(ply)
end

timer.Create("gmInte:API:RelayTimeout", 1, 0, function()
    for ply, transfer in pairs(active) do
        if not IsValid(ply) then release(ply)
        elseif transfer.expires <= CurTime() then reject(ply, transfer.id, 504, "request_timeout") end
    end
end)

hook.Add("PlayerDisconnected", "gmInte:API:RelayCleanup", function(ply)
    release(ply)
    rates[ply] = nil
end)
