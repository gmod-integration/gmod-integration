//
// Websocket
//

function gmInte.wsSyncKick(data)
    for _, ply in ipairs(player.GetAll()) do
        if (ply:SteamID64() == data.steam) then
            ply:Kick(data.reason || "You have been banned from the server.")
        end
    end
end

//
// Methods
//

function gmInte.playerKick(data)
    gmInte.http.post("/servers/:serverID/players/" .. util.SteamIDTo64(data.networkid) .. "/kick", data)
end

//
// Hooks
//

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "gmInte:SyncKick:Disconnect", function(data)
    if (string.StartWith(data.reason, "Kicked by ") || data.reason == "No reason provided.") then
        gmInte.playerKick(data)
    end
end)