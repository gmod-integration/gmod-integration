//
// Network
//

/*
Upload
    0 - Say I'm ready
    1 - Test Connection
    2 - Get Config
Receive
    1 - Sync Chat
    2 - Get Config (Response)
    3 - Test Connection (Response)
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
    end
}

net.Receive("gmIntegration", function()
    local id = net.ReadUInt(8)
    local args = util.JSONToTable(net.ReadString())
    if (netFunc[id]) then netFunc[id](args) end
end)