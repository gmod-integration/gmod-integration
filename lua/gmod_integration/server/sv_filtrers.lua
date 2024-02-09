//
// Methods
//

local function filterMessage(reason)
    local Message = {
        "",
        "This server has player filtering enabled",
        "You are not allowed to join this server",
        "",
        "Reason: " .. reason,
        "",
        "For more information, please contact the server owner",
        "Help URL: " .. (gmInte.config.supportLink && gmInte.config.supportLink || "No Support Link"),
        "",
        "You can also contact us on our discord server",
        "https://gmod-integration.com/discord",
        "",
        "Have a nice day",
        "",
        "Service provided by Gmod Integration",
    }

    for k, v in pairs(Message) do
        Message[k] = v .. "\n"
    end

    return table.concat(Message)
end

local function checkTrustFactor(trustLevel)
    if (gmInte.config.filterOnTrust && (trustLevel < gmInte.config.minimalTrust)) then
        return false
    end

    return true
end

local function checkBanStatus(banStatus)
    if (gmInte.config.filterOnBan && banStatus) then
        return false
    end

    return true
end

local function checkDiscordBanStatus(banStatus)
    if (gmInte.config.syncBan && banStatus) then
        return false
    end

    return true
end

local function playerFilter(data)
    if (data.bot == 1) then return end
    data.steamID64 = util.SteamIDTo64(data.networkid)

    gmInte.http.get("/players/" .. data.steamID64,
        function(code, body)
            if (!body || !body.trust) then return end

            if (!checkBanStatus(body.ban)) then
                game.KickID(data.networkid, filterMessage("You are banned from this server"))
            end

            if (!checkDiscordBanStatus(body.discord_ban)) then
                game.KickID(data.networkid, filterMessage("You are banned from our discord server"))
            end

            if (!checkTrustFactor(body.trust)) then
                game.KickID(data.networkid, filterMessage("Your trust factor is too low"))
            end
        end
    )
end

//
// Hooks
//

gameevent.Listen("player_connect")
hook.Add("player_connect", "gmInte:Player:Connect:Filter", function(data)
    playerFilter(data)
end)