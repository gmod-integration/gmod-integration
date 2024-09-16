local function filterMessage(reason)
    local Message = {}
    table.insert(Message, "----------------------------------------")
    table.insert(Message, gmInte.getTranslation("filter.ds.1", "You cannot join this server"))
    table.insert(Message, "")
    table.insert(Message, gmInte.getTranslation("filter.ds.2", "Reason: {1}", reason && reason || gmInte.getTranslation("filter.none", "none")))
    if gmInte.config.supportLink && gmInte.config.supportLink != "" then table.insert(Message, gmInte.getTranslation("filter.ds.3", "Help URL: {1}", gmInte.config.supportLink)) end
    table.insert(Message, "")
    table.insert(Message, gmInte.getTranslation("filter.ds.4", "Have a nice day"))
    table.insert(Message, "----------------------------------------")
    table.insert(Message, gmInte.getTranslation("filter.ds.5", "Service provided by Gmod Integration"))
    for k, v in ipairs(Message) do
        Message[k] = "\n" .. v
    end
    return table.concat(Message)
end

local function checkBanStatus(banStatus)
    if gmInte.config.filterOnBan && banStatus then return false end
    return true
end

local function checkDiscordBanStatus(banStatus)
    if gmInte.config.syncBan && banStatus then return false end
    return true
end

local function checkPlayerFilter(code, body, data)
    if !body then return end
    if data.rank && gmInte.config.adminRank[data.rank] then return end
    if gmInte.config.maintenance && !body.bypassMaintenance && !body.discordAdmin then game.KickID(data.networkid, filterMessage(gmInte.getTranslation("filter.maintenance", "The server is currently under maintenance and you are not whitelisted."))) end
    if !checkBanStatus(body.ban) then game.KickID(data.networkid, filterMessage(gmInte.getTranslation("filter.ban", "You are banned from this server."))) end
    if !checkDiscordBanStatus(body.discord_ban) then game.KickID(data.networkid, filterMessage(gmInte.getTranslation("filter.discord_ban", "You are banned from our discord server."))) end
end

local cachePlayerFilter = {}
local function playerFilter(data)
    if data.bot == 1 then return end
    data.steamID64 = util.SteamIDTo64(data.networkid)
    local cachedData = cachePlayerFilter[data.steamID64]
    if cachedData && cachedData.curTime + 30 > CurTime() then
        checkPlayerFilter(cachedData.code, cachedData.body, data)
        return
    end

    gmInte.http.get("/servers/:serverID/players/" .. data.steamID64, function(code, body)
        cachePlayerFilter[data.steamID64] = {
            ["code"] = code,
            ["body"] = body,
            ["curTime"] = CurTime()
        }

        checkPlayerFilter(code, body, data)
    end, function(code, body) if gmInte.config.maintenance then game.KickID(data.networkid, filterMessage(gmInte.getTranslation("filter.maintenance", "The server is currently under maintenance and you are not whitelisted."))) end end)
end

gameevent.Listen("player_connect")
hook.Add("player_connect", "gmInte:Player:Connect:Filter", function(data) playerFilter(data) end)