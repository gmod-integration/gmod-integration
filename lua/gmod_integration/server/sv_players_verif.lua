gmInte.plyInVerifQueue = gmInte.plyInVerifQueue || {}
function gmInte.verifyPlayer(ply)
    if !gmInte.config.forcePlayerLink then return end
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    ply:Freeze(true)
    gmInte.http.get("/users?steamID64=" .. ply:SteamID64(), function(code, data)
        if data && data.discordID then ply.gmIntVerified = true end
        if !gmInte.config.forcePlayerLink || !ply.gmIntIsReady then return end
        if ply:gmIntIsVerified() then
            gmInte.plyInVerifQueue[ply:SteamID64()] = nil
            gmInte.SendNet("chatColorMessage", {
                [1] = {
                    ["text"] = gmInte.getTranslation("verification.success", "You have been verified"),
                    ["color"] = Color(255, 255, 255)
                }
            }, ply)

            ply:Freeze(false)
        else
            gmInte.plyInVerifQueue[ply:SteamID64()] = ply
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
        gmInte.plyInVerifQueue[ply:SteamID64()] = ply
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

gmInte.plyInVerifBranchQueue = gmInte.plyInVerifBranchQueue || {}
function gmInte.verifyPlayerBranch(ply)
    if gmInte.config.clientBranch == "any" then return end
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    ply:Freeze(true)
    gmInte.plyInVerifBranchQueue[ply:SteamID64()] = ply
end

function gmInte.blockFamilySharing(ply)
    if !gmInte.config.verifyFamilySharing then return end
    if !ply:IsValid() || !ply:IsPlayer(ply) || ply:IsBot() || !ply:IsFullyAuthenticated() then return end
    if ply:OwnerSteamID64() == ply:SteamID64() then return end
    ply:Kick(gmInte.getTranslation("verification.family_sharing", "This server does not allow family sharing"))
end

hook.Add("gmInte:PlayerReady", "gmInte:Verif:PlayerReady", function(ply)
    ply.gmIntIsReady = true
    gmInte.verifyPlayer(ply)
    gmInte.verifyPlayerBranch(ply)
    gmInte.blockFamilySharing(ply)
end)

// Routine to check the verification of players and kick them if they don't verify
timer.Create("gmInte:Verif:Check:forcePlayerLink", 30, 0, function()
    if !gmInte.config.forcePlayerLink || gmInte.config.verifyOnReadyKickTime == 0 then return end
    for steamID64, ply in pairs(gmInte.plyInVerifQueue) do
        if !ply:IsValid() || !ply:IsPlayer(ply) then continue end
        local connectTime = math.Round(RealTime() - ply:gmIntGetConnectTime())
        gmInte.SendNet("chatColorMessage", {
            [1] = {
                ["text"] = gmInte.getTranslation("verification.kick_in", "If you don't verify in {1} seconds you will be kicked", gmInte.config.verifyOnReadyKickTime - connectTime),
                ["color"] = Color(224, 89, 89)
            }
        }, ply)

        if connectTime >= gmInte.config.verifyOnReadyKickTime then ply:Kick(gmInte.getTranslation("verification.kick", "You have been kicked for not verifying, verify your account on {1}", "https://gmod-integration.com/account")) end
        gmInte.plyInVerifQueue[ply:SteamID64()] = nil
    end
end)

timer.Create("gmInte:Verif:Check:forcePlayerBranch", 30, 0, function()
    if gmInte.config.clientBranch == "any" then return end
    for steamID64, ply in pairs(gmInte.plyInVerifBranchQueue) do
        if !ply:IsValid() || !ply:IsPlayer(ply) then continue end
        local connectTime = math.Round(RealTime() - ply:gmIntGetConnectTime())
        gmInte.SendNet("chatColorMessage", {
            [1] = {
                ["text"] = gmInte.getTranslation("verification.kick_in_branch", "If you don't change your branch in {1} seconds you will be kicked", (gmInte.config.verifyOnReadyKickTime != 0 && gmInte.config.verifyOnReadyKickTime || 600) - connectTime),
                ["color"] = Color(224, 89, 89)
            }
        }, ply)

        if connectTime >= (gmInte.config.verifyOnReadyKickTime != 0 && gmInte.config.verifyOnReadyKickTime || 600) then ply:Kick(gmInte.getTranslation("verification.kick_branch", "You have been kicked for not changing your branch to {1}", gmInte.config.clientBranch)) end
    end
end)