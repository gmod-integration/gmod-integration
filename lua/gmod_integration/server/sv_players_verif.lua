//
// Methods
//

function gmInte.verifyPlayer(ply)
    if (!ply:IsValid() || !ply:IsPlayer(ply)) then return end

    gmInte.http.get("/players/" .. ply:SteamID64(), function(code, data)
        if (!gmInte.config.forcePlayerLink) then return end

        if (data && data.steamID64) then
            if (ply.gmIntVerified) then return end
            gmInte.SendNet("chatColorMessage", {
                [1] = {
                    ["text"] = "You have been verified",
                    ["color"] = Color(255, 255, 255)
                }
            }, ply)
            ply:Freeze(false)
            ply.gmIntVerified = true
        else
            gmInte.SendNet("chatColorMessage", {
                [1] = {
                    ["text"] = "You are not verified",
                    ["color"] = Color(255, 0, 0)
                }
            }, ply)
            ply:Freeze(true)
            gmInte.SendNet("openVerifPopup", nil, ply)
        end
    end)
end

//
// Hooks
//

hook.Add("gmInte:PlayerReady", "gmInte:Verif:PlayerReady", function(ply)
    if (!gmInte.config.forcePlayerLink) then return end

    gmInte.verifyPlayer(ply)
end)