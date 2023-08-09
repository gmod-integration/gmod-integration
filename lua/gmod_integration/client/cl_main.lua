// Networking

/*
Upload
    0 - Say I'm ready
Receive
*/

// net function
function gmInte.SendNet(id, args)
    net.Start("gmIntegration")
    net.WriteUInt(id, 8)
    net.WriteString(util.TableToJSON(args || {}))
    net.SendToServer()
end

hook.Add("InitPostEntity", "gmInte:Ply:Ready", function()
    gmInte.SendNet(0)
end)