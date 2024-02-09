//
// Network
//

/*
Upload
    1 - Add Chat Message
    2 - Get Config
    3 - Test Connection
    4 - Take Screenshot
    5 - Send Public Config
    6 - Send Message
    7 - Open Verif Popup
Receive
    0 - Player is Ready
    1 - Test Connection
    2 - Get Config
    3 - Set Config
    4 - Take Screenshot
    5 - Restart Map
*/

util.AddNetworkString("gmIntegration")

// Send
function gmInte.SendNet(id, data, ply, func)
    net.Start("gmIntegration")
        net.WriteUInt(id, 8)
        net.WriteString(util.TableToJSON(data || {}))
        if (func) then func() end
    if (ply == nil) then
        net.Broadcast()
    else
        net.Send(ply)
    end
end

// Receive
local netFuncs = {
    [0] = function(ply)
        gmInte.userFinishConnect(ply)
    end,
    [1] = function(ply, data)
        gmInte.testConnection(ply, data)
    end,
    [2] = function(ply)
        gmInte.superadminGetConfig(ply)
    end,
    [3] = function(ply, data)
        gmInte.superadminSetConfig(ply, data)
    end,
    [4] = function(ply)
        gmInte.takeScreenshot(ply)
    end,
    [5] = function(ply)
        if (!ply:IsSuperAdmin()) then return end
        RunConsoleCommand("changelevel", game.GetMap())
    end,
    [6] = function(ply)
        gmInte.verifyPlayer(ply)
    end
}

net.Receive("gmIntegration", function(len, ply)
    if !ply:IsPlayer() then return end
    local id = net.ReadUInt(8)
    local data = util.JSONToTable(net.ReadString() || "{}")
    if (netFuncs[id]) then netFuncs[id](ply, data) end
end)