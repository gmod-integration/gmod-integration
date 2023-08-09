//
// Hooks
//

// Server
hook.Add("ShutDown", "gmInte:Server:ShutDown", function()
    gmInte.serverShutDown(ply)
end)
// set convar sv_hibernate_think to 1
hook.Add("Initialize", "gmInte.sendStatus", function()
    timer.Simple(1, function()
        gmInte.sendStatus()
    end)
end)

// Player
gameevent.Listen("player_connect")
hook.Add("player_connect", "gmInte:Player:Connect", function(data)
    gmInte.playerConnect(data)
end)
hook.Add("PlayerDisconnected", "gmInte:Player:Disconnect", function(ply)
    gmInte.playerDisconnected(ply)
end)
hook.Add("onPlayerChangedName", "gmInte:PlayerChangeName", function(ply, old, new)
    gmInte.playerChangeName(ply, old, new)
end)