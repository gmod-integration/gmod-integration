local recent = {}
local MAX_RECENT = 128

local function validateEnvelope(data, method, actorKey, actorMinimum, actorMaximum, nonblank)
    if !istable(data) || data.method != method then return false end
    for key in pairs(data) do
        if key != "method" && key != "requestID" && key != actorKey && key != "command" && key != "expiresAt" then return false end
    end
    return isstring(data.requestID) && #data.requestID == 36 && string.match(data.requestID, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") != nil
        && isstring(data[actorKey]) && #data[actorKey] >= actorMinimum && #data[actorKey] <= actorMaximum && string.match(data[actorKey], "^%d+$") != nil
        && isstring(data.command) && #data.command > 0 && #data.command <= 8192 && !string.find(data.command, "[%z\r\n]")
        && (!nonblank || string.find(data.command, "%S") != nil)
        && isnumber(data.expiresAt) && data.expiresAt == math.floor(data.expiresAt)
end

function gmInte.validateRconCommand(data)
    return validateEnvelope(data, "wsAuthorizedRcon", "steamID", 17, 17, false)
end

function gmInte.validatePanelRconCommand(data)
    return validateEnvelope(data, "wsPanelRcon", "actorDiscordID", 1, 20, true)
end

local function executeRcon(data, actorID, authorize)
    local now = os.time() * 1000
    -- os.time has second precision: expire conservatively instead of executing after the deadline.
    if data.expiresAt <= now + 1000 || data.expiresAt > now + 10000 then return false, "expired" end
    local count = 0
    for id, result in pairs(recent) do
        if result.expiresAt <= now then recent[id] = nil else count = count + 1 end
    end
    local previous = recent[data.requestID]
    if previous then
        if previous.method != data.method || previous.actorID != actorID || previous.command != data.command || previous.expiresAt != data.expiresAt then return false, "execution_failed" end
        return previous.ok, previous.code
    end
    if count >= MAX_RECENT then return false, "execution_failed" end
    -- Reserve before any side effect: reconnects and duplicate delivery must not run a command twice.
    local result = { method = data.method, actorID = actorID, command = data.command, expiresAt = data.expiresAt, ok = false, code = "permission_denied" }
    recent[data.requestID] = result
    if !authorize() then return false, result.code end
    gmInte.log(data.method == "wsPanelRcon" && "Panel RCON command requested by Discord account " .. actorID || "Rcon command requested by linked Steam account " .. actorID)
    local executed = pcall(game.ConsoleCommand, data.command .. "\n")
    result.ok = executed
    result.code = executed && "executed" || "execution_failed"
    return result.ok, result.code
end

function gmInte.wsAuthorizedRcon(data)
    if !gmInte.validateRconCommand(data) then return false, "execution_failed" end
    return executeRcon(data, data.steamID, function()
        local ply = player.GetBySteamID64(data.steamID)
        return IsValid(ply) && isfunction(ply.gmIntIsAdmin) && ply:gmIntIsAdmin() == true
    end)
end

function gmInte.wsPanelRcon(data)
    if !gmInte.validatePanelRconCommand(data) then return false, "execution_failed" end
    -- Only the authenticated, ready gateway may dispatch this method. The platform checks
    -- the actor's panel rights; no Steam account or in-game player is an authorization input.
    return executeRcon(data, data.actorDiscordID, function() return true end)
end
