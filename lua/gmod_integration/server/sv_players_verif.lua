function gmInte.verifyPlayer(ply)
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    gmInte.http.get("/users?steamID64=" .. ply:SteamID64(), function(code, data)
        if data && data.discordID then ply.gmIntVerified = true end
        if !gmInte.config.forcePlayerLink || !ply.gmIntIsReady then return end
        if ply:gmIntIsVerified() then
            gmInte.SendNet("chatColorMessage", {
                [1] = {
                    ["text"] = gmInte.getTranslation("verification.success", "You have been verified"),
                    ["color"] = Color(255, 255, 255)
                }
            }, ply)

            ply:Freeze(false)
        else
            gmInte.SendNet("chatColorMessage", {
                [1] = {
                    ["text"] = gmInte.getTranslation("verification.fail", "Failed to verify you"),
                    ["color"] = Color(255, 0, 0)
                }
            }, ply)

            ply:Freeze(true)
            gmInte.SendNet("openVerifPopup", nil, ply)
        end
    end, function(code, data)
        ply:Freeze(true)
        gmInte.SendNet("chatColorMessage", {
            [1] = {
                ["text"] = gmInte.getTranslation("verification.link_require", "This server requires you to link your Discord account to play"),
                ["color"] = Color(255, 0, 0)
            }
        }, ply)

        gmInte.SendNet("openVerifPopup", nil, ply)
    end)
end

hook.Add("gmInte:PlayerReady", "gmInte:Verif:PlayerReady", function(ply)
    ply.gmIntIsReady = true
    if !gmInte.config.forcePlayerLink then return end
    ply:Freeze(true)
    gmInte.verifyPlayer(ply)
end)