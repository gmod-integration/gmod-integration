//
// Methods
//

function gmInte.verifyPlayer(ply)
    if (!gmInte.plyValid(ply)) then return end
    gmInte.http.get("/players/" .. ply:SteamID64(), function(code, data)
        if (!gmInte.config.forcePlayerLink) then return end

        if (data && data.steamID64) then
            if (ply.gmIntVerified) then return end
            gmInte.SendNet(6, {
                [1] = {
                    ["text"] = "You have been verified",
                    ["color"] = Color(255, 255, 255)
                }
            }, ply)
            ply:Freeze(false)
            ply.gmIntVerified = true
        else
            gmInte.SendNet(6, {
                [1] = {
                    ["text"] = "You are not verified",
                    ["color"] = Color(255, 0, 0)
                }
            }, ply)
            ply:Freeze(true)
            gmInte.SendNet(7, nil, ply)
        end
    end)
end

// Generate a unique token that allow player to update data link to this server (ex: screnshot, report bug, etc.)
function gmInte.getClientOneTimeToken(ply, callback)
    gmInte.http.get("/players/" .. ply:SteamID64() .. "/get-one-time-token", function(code, data)
        callback(data.token)
    end)
end

function gmInte.playerConnect(data)
    gmInte.http.post("/players/" .. util.SteamIDTo64(data.networkid) .. "/connect", data)
end

function gmInte.userFinishConnect(ply)
    if (!gmInte.plyValid(ply)) then return end

    // Initialize Time
    ply.gmIntTimeConnect = math.Round(RealTime())

    // Send Public Config
    gmInte.publicGetConfig(ply)

    gmInte.http.post("/players/" .. ply:SteamID64() .. "/finish-connect", gmInte.getPlayerFormat(ply))

    if (!gmInte.config.forcePlayerLink) then return end
    gmInte.verifyPlayer(ply)
end

function gmInte.playerDisconnected(ply)
    if (!gmInte.plyValid(ply)) then return end

    gmInte.http.post("/players/" .. ply:SteamID64() .. "/disconnect",
        {
            ["player"] = gmInte.getPlayerFormat(ply),
        }
    )
end

//
// Hooks
//

hook.Add("ShutDown", "gmInte:Server:Shutdown:SavePlayers", function()
    for ply, ply in pairs(player.GetAll()) do
        gmInte.playerDisconnected(ply)
    end
end)

gameevent.Listen("player_connect")
hook.Add("player_connect", "gmInte:Player:Connect", function(data)
    gmInte.playerConnect(data)
end)

hook.Add("PlayerDisconnected", "gmInte:Player:Disconnect", function(ply)
    gmInte.playerDisconnected(ply)
end)