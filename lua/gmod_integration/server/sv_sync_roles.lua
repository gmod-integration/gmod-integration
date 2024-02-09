//
// Websocket
//

function gmInte.wsSyncRoles(data)
    local ply = player.GetBySteamID(data.steamID)
    if (ply:IsValid()) then
        ply:SetUserGroup(data.role)
    end

    // ULX
    if (ULib) then
        ULib.ucl.addUser(data.steamID, nil, nil, data.role)
    end

    // FAdmin
    if (CAMI) then
        CAMI.PlayerRank(data.steamID64, data.role, "user")
    end

    // ServerGuard
    if (serverguard) then
        serverguard.player:SetRank(data.steamID64, data.role)
    end

    // Evolve
    if (evolve) then
        evolve:RankPlayer(data.steamID64, data.role)
    end

    // SAM
    if (SAM) then
        SAM:PlayerSetRank(data.steamID64, data.role)
    end
end