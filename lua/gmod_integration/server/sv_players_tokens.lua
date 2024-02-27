//
// Methods
//

function gmInte.getClientOneTimeToken(ply, callback)
    if (!ply:IsValid() || !ply:IsPlayer()) then return end

    gmInte.http.get("/players/" .. ply:SteamID64() .. "/single-token", function(code, data)
        if (callback) then callback(data) end
    end)
end

function gmInte.createClientToken(ply, callback)
    if (!ply:IsValid() || !ply:IsPlayer()) then return end

    gmInte.http.get("/players/" .. ply:SteamID64() .. "/tokens", function(code, data)
        if (callback) then callback(data) end
    end)
end

function gmInte.revokeClientToken(ply, callback)
    if (!ply:IsValid() || !ply:IsPlayer()) then return end

    gmInte.http.delete("/players/" .. ply:SteamID64() .. "/tokens", function(code, data)
        if (callback) then callback(data) end
    end)
end