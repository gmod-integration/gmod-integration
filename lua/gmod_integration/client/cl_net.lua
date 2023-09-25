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
        func && func()
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
    netFunc[id] && netFunc[id](args)
end)