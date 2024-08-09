util.AddNetworkString("gmIntegration")
local netSend = {
    ["wsRelayDiscordChat"] = 1,
    ["adminConfig"] = 2,
    ["testApiConnection"] = 3,
    ["publicConfig"] = 5,
    ["chatColorMessage"] = 6,
    ["openVerifPopup"] = 7,
    ["savePlayerToken"] = 8
}

// Send
function gmInte.SendNet(id, data, ply, func)
    if !netSend[id] then return end
    net.Start("gmIntegration")
    net.WriteUInt(netSend[id], 8)
    net.WriteString(util.TableToJSON(data || {}))
    if func then func() end
    if ply == nil then
        net.Broadcast()
    else
        net.Send(ply)
    end
end

local netReceive = {
    [0] = function(ply) hook.Run("gmInte:PlayerReady", ply) end,
    [1] = function(ply, data) gmInte.testConnection(ply, data) end,
    [2] = function(ply) gmInte.superadminGetConfig(ply) end,
    [3] = function(ply, data) gmInte.superadminSetConfig(ply, data) end,
    [4] = function(ply) gmInte.takeScreenshot(ply) end,
    [5] = function(ply)
        if !ply:gmIntIsAdmin() then return end
        RunConsoleCommand("changelevel", game.GetMap())
    end,
    [6] = function(ply) gmInte.verifyPlayer(ply) end,
    [7] = function(ply, data) gmInte.sendPlayerToken(ply) end
}

net.Receive("gmIntegration", function(len, ply)
    if !ply || ply && !ply:IsValid() then return end
    local id = net.ReadUInt(8)
    local data = util.JSONToTable(net.ReadString() || "{}")
    if !netReceive[id] then return end
    netReceive[id](ply, data)
end)