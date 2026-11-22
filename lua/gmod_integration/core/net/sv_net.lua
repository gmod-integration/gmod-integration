util.AddNetworkString("gmIntegration")
function gmInte.SendNet(id, data, ply, func)
    net.Start("gmIntegration")
    net.WriteString(id)
    net.WriteString(util.TableToJSON(data || {}))
    if func then func() end
    if ply == nil then
        net.Broadcast()
    else
        net.Send(ply)
    end
end

local netReceive = {
    ["ready"] = function(ply, data)
        if ply.gmIntIsReady then return end
        ply.branch = data.branch
        hook.Run("gmInte:PlayerReady", ply)
    end,
    ["testConnection"] = function(ply, data) if ply:gmIntIsAdmin() then gmInte.testConnection(ply, data) end end,
    ["getConfig"] = function(ply) gmInte.superadminGetConfig(ply) end,
    ["saveConfig"] = function(ply, data) gmInte.superadminSetConfig(ply, data) end,
    ["takeScreenShot"] = function(ply) gmInte.takeScreenshot(ply) end,
    ["restartMap"] = function(ply)
        if !ply:gmIntIsAdmin() then return end
        RunConsoleCommand("changelevel", game.GetMap())
    end,
    ["verifyMe"] = function(ply) gmInte.verifyPlayer(ply) end,
    ["sendFPS"] = function(ply, data) ply:gmInteSetFPS(data.fps) end,
}

net.Receive("gmIntegration", function(len, ply)
    if !IsValid(ply) || !ply:IsPlayer() || len > 60000 * 8 then return end
    local id = net.ReadString()
    if #id > 64 || !netReceive[id] then return end
    local json = net.ReadString()
    if #json > 60000 then return end
    local ok, data = pcall(util.JSONToTable, json)
    if !ok || !istable(data) then return end
    netReceive[id](ply, data)
    if gmInte.config.debug then
        gmInte.log("[net] Received net message: " .. id .. " from " .. (ply && ply:Nick() || "Unknown"))
    end
end)
