//
// Server Hooks
//

hook.Add("ShutDown", "gmInte:Server:ShutDown", function()
    gmInte.serverShutDown()
end)

hook.Add("Initialize", "gmInte.sendStatus", function()
    timer.Simple(1, function()
        gmInte.serverStart()
    end)
end)

//
// Player Hooks
//

gameevent.Listen("player_connect")
hook.Add("player_connect", "gmInte:Player:Connect", function(data)
    gmInte.playerConnect(data)
    gmInte.playerFilter(data)
end)

gameevent.Listen("server_addban")
hook.Add("server_addban", "gmInte:Player:Ban", function(data)
    gmInte.playerBan(data)
end)

hook.Add("PlayerDisconnected", "gmInte:Player:Disconnect", function(ply)
    gmInte.playerDisconnected(ply)
end)

hook.Add("onPlayerChangedName", "gmInte:PlayerChangeName", function(ply, old, new)
    gmInte.playerChangeName(ply, old, new)
end)

hook.Add("PlayerSay", "gmInte:PlayerSay", function(ply, text, team)
    gmInte.playerSay(ply, text, team)
end)