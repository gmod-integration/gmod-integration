//
// Websocket
//

function gmInte.wsSyncBan(data)
    for _, ply in ipairs(player.GetAll()) do
        if (ply:SteamID64() == data.steam) then
            ply:Kick(data.reason || "You have been banned from the server.")
        end
    end
end

//
// Methods
//

function gmInte.playerBan(data)
    gmInte.http.post("/players/" .. util.SteamIDTo64(data.networkid) .. "/ban", data)
end

//
// Hooks
//

gameevent.Listen("server_addban")
hook.Add("server_addban", "gmInte:Player:Ban", function(data)
    gmInte.playerBan(data)
end)