//
// Websocket
//

function gmInte.wsPlayerScreen(data)
    for _, ply in pairs(player.GetAll()) do
        if (ply:SteamID64() == data.steamID64) then
            gmInte.takeScreenshot(ply)
        end
    end
end

//
// Methods
//

function gmInte.takeScreenshot(ply)
    gmInte.getClientOneTimeToken(ply, function(oneTime)
        gmInte.SendNet("screenshotToken", {
            ["serverID"] = gmInte.config.id,
            ["oneTimeToken"] = oneTime
        }, ply)
    end)
end