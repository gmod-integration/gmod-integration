function gmInte.getPlayerFormat(ply)
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
        ["angle"] = gmInte.getAngleFormat(ply:EyeAngles())
    }
end

function gmInte.getServerFormat()
    return {
        ["hostname"] = GetHostName(),
        ["ip"] = game.GetIPAddress(),
        ["port"] = GetConVar("hostport"):GetInt(),
        ["map"] = game.GetMap(),
        ["players"] = #player.GetAll(),
        ["maxPlayers"] = game.MaxPlayers(),
        ["gameMode"] = engine.ActiveGamemode(),
        ["uptime"] = math.Round(RealTime())
    }
end

function gmInte.getWeaponFormat(weapon)
    return {
        ["class"] = weapon:GetClass(),
        ["printName"] = weapon:GetPrintName()
    }
end

function gmInte.getEntityFormat(ent)
    return {
        ["class"] = ent:GetClass(),
        ["model"] = ent:GetModel(),
        ["position"] = gmInte.getVectorFormat(ent:GetPos()),
        ["angle"] = gmInte.getAngleFormat(ent:GetAngles())
    }
end

function gmInte.getVectorFormat(vec)
    return {
        ["x"] = vec.x,
        ["y"] = vec.y,
        ["z"] = vec.z
    }
end

function gmInte.getAngleFormat(ang)
    return {
        ["p"] = ang.p,
        ["y"] = ang.y,
        ["r"] = ang.r
    }
end

function gmInte.getTeamFormat(teamID)
    return {
        ["id"] = teamID,
        ["name"] = team.GetName(teamID)
    }
end