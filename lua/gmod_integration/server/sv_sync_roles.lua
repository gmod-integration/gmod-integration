local cachedPlayers = {}
function gmInte.wsPlayerUpdateGroup(data)
    gmInte.log("[Sync Role] Player " .. data.steamID64 .. " has been updated to group " .. data.group, true)
    if cachedPlayers[steamID64] == data.group then return end
    data.steamID = util.SteamIDFrom64(data.steamID64)
    data.group = data.add && data.group || "user"
    cachedPlayers[data.steamID64] = data.group
    local ply = player.GetBySteamID(data.steamID)
    if ply && ply:IsValid() then ply:SetUserGroup(data.group) end
    // ULX
    if ULib then
        if data.group == "user" then
            ULib.ucl.removeUser(data.steamID)
        else
            ULib.ucl.addUser(data.steamID, nil, nil, data.group)
        end
    end

    // ServerGuard
    if serverguard then
        local ply = player.GetBySteamID(data.steamID)
        if ply then
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
    if evolve then evolve:RankPlayer(data.steamID64, data.group) end
    // sam - the gmodstore
    if sam then sam.player.set_rank_id(data.steamID, data.group) end
    // SAM - the other one
    if SAM then SAM:PlayerSetRank(data.steamID64, data.group) end
    // xAdmin
    if xAdmin then xAdmin.SetRank(data.steamID64, data.group) end
    // sAdmin
    if sAdmin then RunConsoleCommand("sa", "setrankid", data.steamID, data.group) end
    // maestro
    if maestro then maestro.userrank(data.steamID64, data.group) end
    // D3A
    if D3A then D3A.Ranks.SetSteamIDRank(data.steamID, data.group) end
    // Mercury
    if Mercury then RunConsoleCommand("hg", "setrank", data.steamID, data.group) end
    // FAdmin
    if FAdmin then RunConsoleCommand("fadmin", "setaccess", data.steamID, data.group) end
    // Nor Admin Mod for GMod
    if nordahl_cfg_3916 then RunConsoleCommand("add_staff", data.steamID64, "\"" .. data.steamID .. "\"", "\"" .. data.group .. "\"") end
    gmInte.log("[Sync Role] Player " .. data.steamID .. " has been updated to group " .. data.group)
end

function gmInte.playerChangeGroup(steamID64, oldGroup, newGroup)
    if cachedPlayers[steamID64] == newGroup then return end
    cachedPlayers[steamID64] = newGroup
    gmInte.http.post("/servers/:serverID/players/" .. steamID64 .. "/group", {
        ["oldGroup"] = oldGroup || "user",
        ["newGroup"] = newGroup
    })
end

// CAMI
hook.Add("CAMI.PlayerUsergroupChanged", "gmInte:SyncRoles:CAMI:PlayerUsergroupChanged", function(ply, old, new)
    if ply:IsBot() || !ply:IsValid() then return end
    gmInte.playerChangeGroup(ply:SteamID64(), old, new)
end)

hook.Add("CAMI.SteamIDUsergroupChanged", "gmInte:SyncRoles:CAMI:SteamIDUsergroupChanged", function(SteamID64, old, new)
    if string.StartWith(SteamID64, "STEAM_") then SteamID64 = util.SteamIDTo64(SteamID64) end
    gmInte.playerChangeGroup(SteamID64, old, new)
end)

// For those who refuse to use CAMI (bro, WTF), routine scan
local lastScan = {}
timer.Create("gmInte:SyncRoles:PlayerScan", 3, 0, function()
    for k, v in ipairs(player.GetAll()) do
        if lastScan[v:SteamID64()] == v:GetUserGroup() then continue end
        gmInte.playerChangeGroup(v:SteamID64(), lastScan[v:SteamID64()], v:GetUserGroup())
        lastScan[v:SteamID64()] = v:GetUserGroup()
    end
end)