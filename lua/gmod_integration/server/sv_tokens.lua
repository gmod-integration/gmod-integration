gmInte.serverPublicToken = gmInte.serverPublicToken || nil
function gmInte.getPublicServerToken(callback)
    if gmInte.serverPublicToken then
        if callback then callback(gmInte.serverPublicToken) end
        return
    end

    gmInte.http.get("/servers/:serverID/public-token", function(code, data)
        gmInte.serverPublicToken = data.publicTempToken
        callback(data.publicTempToken)
    end)
end

gmInte.serverPlayerTempTokens = gmInte.serverPlayerTempTokens || {}
function gmInte.getPlayerTempToken(ply, callback)
    if gmInte.serverPlayerTempTokens[ply:SteamID64()] && gmInte.serverPlayerTempTokens[ply:SteamID64()].userID == ply:UserID() then
        if callback then callback(gmInte.serverPlayerTempTokens[ply:SteamID64()].token) end
        return
    end

    gmInte.getPublicServerToken(function(publicToken)
        local token = util.SHA256(ply:SteamID64() .. "-" .. publicToken .. "-" .. gmInte.config.token .. "-" .. ply:UserID()) .. " " .. ply:UserID()
        gmInte.serverPlayerTempTokens[ply:SteamID64()] = {
            token = token,
            userID = ply:UserID()
        }

        callback(token)
    end)
end

function gmInte.sendPlayerToken(ply)
    gmInte.getPlayerTempToken(ply, function(token)
        gmInte.SendNet("savePlayerToken", {
            token = token,
        }, ply)
    end)
end

hook.Add("gmInte:PlayerReady", "gmInte:Verif:PlayerReady", function(ply) sendPlayerToken(ply) end)
hook.Add("Initialize", "gmInte:Server:Initialize:GetPublicToken", function() timer.Simple(1, function() gmInte.getPublicServerToken(function(publicToken) gmInte.log("Server Public Token Received: " .. publicToken) end) end) end)