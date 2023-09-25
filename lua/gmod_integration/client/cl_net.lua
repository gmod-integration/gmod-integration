//
// Network
//

/*
Upload
    0 - Say I'm ready
Receive
    1 - Sync Chat
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
    [1] = function(args)
        chat.AddText(unpack(args))
    end
}

net.Receive("gmIntegration", function()
    local id = net.ReadUInt(8)
    local args = util.JSONToTable(net.ReadString())
    if (netFunc[id]) then netFunc[id](args) end
end)