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
    ["testConnection"] = function(ply, data) gmInte.testConnection(ply, data) end,
    ["getConfig"] = function(ply) gmInte.superadminGetConfig(ply) end,
    ["saveConfig"] = function(ply, data) gmInte.superadminSetConfig(ply, data) end,
    ["takeScreenShot"] = function(ply) gmInte.takeScreenshot(ply) end,
    ["restartMap"] = function(ply)
        if !ply:gmIntIsAdmin() then return end
        RunConsoleCommand("changelevel", game.GetMap())
    end,
    ["verifyMe"] = function(ply) gmInte.verifyPlayer(ply) end,
    ["sendFPS"] = function(ply, data) ply:gmInteSetFPS(fps) end,
}

net.Receive("gmIntegration", function(len, ply)
    if !ply || ply && !ply:IsValid() then return end
    local id = net.ReadString()
    local data = util.JSONToTable(net.ReadString() || "{}")
    if !netReceive[id] then return end
    netReceive[id](ply, data)
    if gmInte.config.debug then
        gmInte.log("[net] Received net message: " .. id .. " from " .. (ply && ply:Nick() || "Unknown"))
        gmInte.log("[net] Data: " .. util.TableToJSON(data))
    end
end)