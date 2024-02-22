//
// Websocket
//

function gmInte.wsPlayerSay(data)
    gmInte.SendNet("wsRelayDiscordChat", data, nil)
end

//
// Methods
//

function gmInte.playerSay(ply, text, teamOnly)
    if (!gmInte.config.syncChat) then return end

    gmInte.http.post("/players/" .. ply:SteamID64() .. "/say",
        {
            ["player"] = gmInte.getPlayerFormat(ply),
            ["text"] = text,
            ["teamOnly"] = teamOnly,
        }
    )
end

//
// Hooks
//

hook.Add("PlayerSay", "gmInte:PlayerSay:SyncChat", function(ply, text, team)
    gmInte.playerSay(ply, text, team)
end)