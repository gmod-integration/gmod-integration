//
// Methods
//

local function filterMessage(reason)
    local Message = {
        "\n----------------------------------------\n",
        "You cannot join this server",
        "",
        "Reason: " .. (reason && reason || "none"),
        "Help URL: " .. (gmInte.config.supportLink && gmInte.config.supportLink || "none"),
        "",
        "Have a nice day",
        "\n----------------------------------------\n",
        "Service provided by Gmod Integration",
    }

    for k, v in pairs(Message) do
        Message[k] = "\n" .. v
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
            if (gmInte.config.maintenance && !body.bypassMaintenance && !body.discordAdmin) then
                game.KickID(data.networkid, filterMessage("The server is currently under maintenance and you are not whitelisted."))
            end

            if (!checkBanStatus(body.ban)) then
                game.KickID(data.networkid, filterMessage("You are banned from this server."))
            end

            if (!checkDiscordBanStatus(body.discord_ban)) then
                game.KickID(data.networkid, filterMessage("You are banned from our discord server."))
            end

            -- if (!checkTrustFactor(body.trust)) then
            --     game.KickID(data.networkid, filterMessage("Your trust factor is too low."))
            -- end
        end,
        function (code, body)
            if (gmInte.config.maintenance) then
                game.KickID(data.networkid, filterMessage("The server is currently under maintenance and we cannot verify your account.\nVerification URL: https://verif.gmod-integration.com"))
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