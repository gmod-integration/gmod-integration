function gmInte.wsSyncBan(data)
    for _, ply in pairs(player.GetAll()) do
        if ply:SteamID64() == data.steam then ply:Kick(data.reason || "You have been banned from the server.") end
    end
end

function gmInte.playerBan(data)
    data.steamID64 = util.SteamIDTo64(data.networkid)
    gmInte.http.post("/servers/:serverID/players/" .. util.SteamIDTo64(data.networkid) .. "/ban", data)
end

gameevent.Listen("server_addban")
hook.Add("server_addban", "gmInte:Player:Ban", function(data) gmInte.playerBan(data) end)