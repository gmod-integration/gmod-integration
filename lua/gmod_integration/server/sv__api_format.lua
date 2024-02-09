function gmInte.playerFormat(ply)
    return {
        steamID = ply:SteamID(),
        steamID64 = ply:SteamID64(),
        userGroup = ply:GetUserGroup(),
        team = ply:Team(),
        teamName = team.GetName(ply:Team()),
        name = ply:Nick(),
        kills = ply:Frags(),
        deaths = ply:Deaths(),
        customValues = ply:gmIntGetCustomValues(),
        connectTime = math.Round(RealTime() - ply:gmIntGetConnectTime()),
    }
end