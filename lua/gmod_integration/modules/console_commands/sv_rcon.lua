local recent = {}
local MAX_RECENT = 128

function gmInte.validateRconCommand(data)
    if !istable(data) || data.method != "wsAuthorizedRcon" then return false end
    for key in pairs(data) do
        if key != "method" && key != "requestID" && key != "steamID" && key != "command" && key != "expiresAt" then return false end
    end
    return isstring(data.requestID) && #data.requestID == 36 && string.match(data.requestID, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") != nil
        && isstring(data.steamID) && #data.steamID == 17 && string.match(data.steamID, "^%d+$") != nil
        && isstring(data.command) && #data.command > 0 && #data.command <= 8192 && !string.find(data.command, "[%z\r\n]")
        && isnumber(data.expiresAt) && data.expiresAt == math.floor(data.expiresAt)
end

function gmInte.wsAuthorizedRcon(data)
    if !gmInte.validateRconCommand(data) then return false, "execution_failed" end
    local now = os.time() * 1000
    -- os.time has second precision: expire conservatively instead of executing after the deadline.
    if data.expiresAt <= now + 1000 || data.expiresAt > now + 10000 then return false, "expired" end
    local count = 0
    for id, result in pairs(recent) do
        if result.expiresAt <= now then recent[id] = nil else count = count + 1 end
    end
    local previous = recent[data.requestID]
    if previous then
        if previous.steamID != data.steamID || previous.command != data.command || previous.expiresAt != data.expiresAt then return false, "execution_failed" end
        return previous.ok, previous.code
    end
    if count >= MAX_RECENT then return false, "execution_failed" end
    -- Reserve before any side effect: reconnects and duplicate delivery must not run a command twice.
    local result = { steamID = data.steamID, command = data.command, expiresAt = data.expiresAt, ok = false, code = "permission_denied" }
    recent[data.requestID] = result
    local ply = player.GetBySteamID64(data.steamID)
    if !IsValid(ply) || !isfunction(ply.gmIntIsAdmin) || ply:gmIntIsAdmin() != true then return false, result.code end
    gmInte.log("Rcon command requested from Discord by " .. data.steamID)
    local executed = pcall(game.ConsoleCommand, data.command .. "\n")
    result.ok = executed
    result.code = executed && "executed" || "execution_failed"
    return result.ok, result.code
end
