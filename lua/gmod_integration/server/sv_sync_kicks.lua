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
    if (data.reason != "Kicked by console" || data.reason != "No reason given") then
        return
    end

    gmInte.http.post("/players/" .. util.SteamIDTo64(data.networkid) .. "/kick", data)
end

//
// Hooks
//

gameevent.Listen("player_disconnect")
hook.Add("player_disconnect", "gmInte:SyncKick:Disconnect", function(data)
    gmInte.playerKick(data)
end)
