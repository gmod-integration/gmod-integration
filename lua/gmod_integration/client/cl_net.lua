//
// Network
//

/*
Upload
    0 - Say I'm ready
    1 - Test Connection
    2 - Get Config
    3 - Save Config
    4 - Take ScreenShot
    5 - Restart Map
    6 - Verify Me
Receive
    1 - Sync Chat
    2 - Get Config
    3 - Test Connection
    4 - Take ScreenShot
    5 - Set Public Config
    6 - Add Chat
    7 - Open Verif Popup
*/

// Send
function gmInte.SendNet(id, args, func)
    net.Start("gmIntegration")
        net.WriteUInt(id, 8)
        net.WriteString(util.TableToJSON(args || {}))
        if (func) then func() end
    net.SendToServer()
end

// Receive
local netFunc = {
    [1] = function(data)
        gmInte.discordSyncChatPly(data)
    end,
    [2] = function(data)
        gmInte.openConfigMenu(data)
    end,
    [3] = function(data)
        gmInte.showTestConnection(data)
    end,
    [4] = function(data)
        gmInte.takeScreenShot(data.serverID, data.authToken)
    end,
    [5] = function(data)
        gmInte.config = data
    end,
    [6] = function(data)
        gmInte.chatAddText(data)
    end,
    [7] = function()
        gmInte.openVerifPopup()
    end
}

net.Receive("gmIntegration", function()
    local id = net.ReadUInt(8)
    local args = util.JSONToTable(net.ReadString())
    if (netFunc[id]) then netFunc[id](args) end
end)