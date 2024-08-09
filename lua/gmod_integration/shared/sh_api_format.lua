function gmInte.getPlayerFormat(ply)
    if !IsValid(ply) || !ply:IsPlayer() then return end
    return {
        ["steamID"] = ply:SteamID(),
        ["steamID64"] = ply:SteamID64(),
        ["userGroup"] = ply:GetUserGroup(),
        ["team"] = gmInte.getTeamFormat(ply:Team()),
        ["name"] = ply:Nick(),
        ["kills"] = ply:Frags(),
        ["deaths"] = ply:Deaths(),
        ["customValues"] = ply:gmIntGetCustomValues(),
        ["connectTime"] = math.Round(RealTime() - ply:gmIntGetConnectTime()),
        ["ping"] = ply:Ping(),
        ["position"] = gmInte.getVectorFormat(ply:GetPos()),
        ["angle"] = gmInte.getAngleFormat(ply:EyeAngles()),
        ["weapon"] = gmInte.getWeaponFormat(ply:GetActiveWeapon())
    }
end

function gmInte.getPlayersFormat()
    local players = {}
    for k, v in ipairs(player.GetAll()) do
        table.insert(players, gmInte.getPlayerFormat(v))
    end
    return players
end

function gmInte.getServerFormat()
    return {
        ["hostname"] = GetHostName(),
        ["ip"] = game.GetIPAddress(),
        ["port"] = GetConVar("hostport"):GetInt(),
        ["map"] = game.GetMap(),
        ["players"] = #player.GetAll(),
        ["playersList"] = gmInte.getPlayersFormat(),
        ["maxPlayers"] = game.MaxPlayers(),
        ["gameMode"] = engine.ActiveGamemode(),
        ["uptime"] = math.Round(RealTime())
    }
end

function gmInte.getWeaponFormat(weapon)
    if !IsValid(weapon) || !weapon:IsWeapon() then return end
    return {
        ["class"] = weapon:GetClass(),
        ["printName"] = weapon:GetPrintName()
    }
end

function gmInte.getEntityFormat(ent)
    if !IsValid(ent) then return end
    return {
        ["class"] = ent:GetClass(),
        ["model"] = ent:GetModel(),
        ["position"] = gmInte.getVectorFormat(ent:GetPos()),
        ["angle"] = gmInte.getAngleFormat(ent:GetAngles())
    }
end

function gmInte.getVectorFormat(vec)
    if !isvector(vec) then return end
    return {
        ["x"] = math.Round(vec.x),
        ["y"] = math.Round(vec.y),
        ["z"] = math.Round(vec.z)
    }
end

function gmInte.getAngleFormat(ang)
    if !isangle(ang) then return end
    return {
        ["p"] = math.Round(ang.p),
        ["y"] = math.Round(ang.y),
        ["r"] = math.Round(ang.r)
    }
end

function gmInte.getTeamFormat(teamID)
    if !isnumber(teamID) then return end
    return {
        ["id"] = teamID,
        ["name"] = team.GetName(teamID)
    }
end