//
// Websocket
//

local cachedPlayers = {}

function gmInte.wsPlayerUpdateGroup(data)
    if (cachedPlayers[steamID64] == data.group) then return end

    data.steamID = util.SteamIDFrom64(data.steamID64)
    data.group = data.add && data.group || "user"

    cachedPlayers[data.steamID64] = data.group

    local ply = player.GetBySteamID(data.steamID)
    if (ply && ply:IsValid()) then
        ply:SetUserGroup(data.group)
    end

    // ULX
    if (ULib) then
        ULib.ucl.addUser(data.steamID, nil, nil, data.group)
    end

    // ServerGuard
    if (serverguard) then
        local ply = player.GetBySteamID(data.steamID)
        if (ply) then
            local rankData = serverguard.ranks:GetRank(data.group)
            serverguard.player:SetRank(ply, data.group)
            serverguard.player:SetImmunity(ply, rankData.immunity)
            serverguard.player:SetTargetableRank(ply, rankData.targetable)
            serverguard.player:SetBanLimit(ply, rankData.banlimit)
        else
            serverguard.player:SetRank(data.steamID, data.group)
        end
    end

    // Evolve
    if (evolve) then
        evolve:RankPlayer(data.steamID64, data.group)
    end

    // SAM
    if (SAM) then
        SAM:PlayerSetRank(data.steamID64, data.group)
    end

    // sam (wtf another one?)
    if (sam) then
        sam.player.setRank(data.steamID64, data.group)
    end

    // xAdmin
    if (xAdmin) then
        xAdmin.SetRank(data.steamID64, data.group)
    end

    // maestro
    if (maestro) then
        maestro.userrank(data.steamID64, data.group)
    end

    // D3A
    if (D3A) then
        D3A.Ranks.SetSteamIDRank(data.steamID, data.group)
    end

    // Mercury
    if (Mercury) then
        RunConsoleCommand("hg", "setrank", data.steamID, data.group)
    end

    // FAdmin
    if (FAdmin) then
        RunConsoleCommand("fadmin", "setaccess", data.steamID, data.group)
    end

    gmInte.log("[Sync Role] Player " .. data.steamID .. " has been updated to group " .. data.group)
end

function gmInte.playerChangeGroup(steamID64, oldGroup, newGroup)
    if (cachedPlayers[steamID64] == newGroup) then return end
    cachedPlayers[steamID64] = newGroup

    gmInte.http.post("/servers/:serverID/players/" .. steamID64 .. "/group", {
        ["player"] = gmInte.getPlayerFormat(ply),
        ["oldGroup"] = oldGroup || "user",
        ["newGroup"] = newGroup
    })
end

hook.Add('CAMI.PlayerUsergroupChanged', 'gmInte:SyncChat:CAMI:PlayerUsergroupChanged', function(ply, old, new)
    if (ply:IsBot() || !ply:IsValid()) then return end
    gmInte.playerChangeGroup(ply:SteamID64(), old, new)
end)

hook.Add('CAMI.SteamIDUsergroupChanged', 'gmInte:SyncChat:CAMI:SteamIDUsergroupChanged', function(SteamID64, old, new)
    if (string.StartWith(SteamID64, "STEAM_")) then SteamID64 = util.SteamIDTo64(SteamID64) end
    gmInte.playerChangeGroup(SteamID64, old, new)
end)