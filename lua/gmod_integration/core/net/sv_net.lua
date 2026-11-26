util.AddNetworkString("gmIntegration")
function gmInte.SendNet(id, data, ply, func)
    local encoded = util.TableToJSON(data || {})
    if !encoded || #encoded > 60000 then return false end
    net.Start("gmIntegration")
    net.WriteString(id)
    net.WriteString(encoded)
    if func then func() end
    if ply == nil then
        net.Broadcast()
    else
        net.Send(ply)
    end
    return true
end

local netReceive = {
    ["ready"] = function(ply, data)
        if ply.gmIntIsReady then return end
        if !isstring(data.branch) || #data.branch > 32 then return end
        ply.branch = data.branch
        hook.Run("gmInte:PlayerReady", ply)
    end,
    ["testConnection"] = function(ply, data) if ply:gmIntIsAdmin() then gmInte.testConnection(ply, data) end end,
    ["getConfig"] = function(ply) gmInte.superadminGetConfig(ply) end,
    ["saveConfig"] = function(ply, data) gmInte.superadminSetConfig(ply, data) end,
    ["restartMap"] = function(ply)
        if !ply:gmIntIsAdmin() then return end
        RunConsoleCommand("changelevel", game.GetMap())
    end,
    ["verifyMe"] = function(ply) gmInte.verifyPlayer(ply) end,
    ["sendFPS"] = function(ply, data)
        if !isnumber(data.fps) || data.fps != data.fps || data.fps < 0 || data.fps > 10000 then return end
        ply:gmInteSetFPS(data.fps)
    end,
    ["apiRelayChunk"] = function(ply, data) gmInte.receiveClientAPIChunk(ply, data) end,
    ["apiRelayCancel"] = function(ply, data) gmInte.cancelClientAPIRelay(ply, data) end,
}

local limits = { testConnection = 2, getConfig = 1, saveConfig = 0.5, restartMap = 5, verifyMe = 2, sendFPS = 0.1 }
local received = {}
net.Receive("gmIntegration", function(len, ply)
    if !IsValid(ply) || !ply:IsPlayer() || len > 60000 * 8 then return end
    local id = net.ReadString()
    if !netReceive[id] || #id > 64 then return end
    local json = net.ReadString()
    local data = gmInte.decodeBoundedNetJSON(json)
    if !istable(data) then return end
    if limits[id] then
        received[ply] = received[ply] || {}
        if (received[ply][id] || 0) > CurTime() then return end
        received[ply][id] = CurTime() + limits[id]
    end
    netReceive[id](ply, data)
    if gmInte.config.debug && id != "apiRelayChunk" && id != "apiRelayCancel" then
        gmInte.log("[net] Received net message: " .. id .. " from " .. (ply && ply:Nick() || "Unknown"))
    end
end)
hook.Add("PlayerDisconnected", "gmInte:Net:RateCleanup", function(ply) received[ply] = nil end)
