//
// Functions
//

function gmInte.removePort(ip)
    return string.Explode(":", ip)[1]
end

function gmInte.plyValid(ply)
    return ply:IsValid() && ply:IsPlayer() && !ply:IsBot()
end

function gmInte.saveSetting(setting, value)
    // save this in data/gmod_integration/setting.json but first check if variable is valid
    if gmInte.config[setting] == nil then
        gmInte.log("Unknown Setting")
        return
    end

    // Boolean
    if (value == "true") then value = true end
    if (value == "false") then value = false end
    // Number
    if (tonumber(value) != nil) then value = tonumber(value) end

    gmInte.config[setting] = value
    file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
    gmInte.log("Setting Saved")
end

function gmInte.playerConnect(data)
    if (data.bot == 1) then return end

    data.steam = util.SteamIDTo64(data.networkid)

    gmInte.post("/server/user/connect", data)
end

local function getTriggerInfo(text)
    for k, v in pairs(gmInte.config.chatTrigger) do
        if (string.StartWith(text, k)) then
            local defaultConfig = {
                    ["trigger"] = k,
                    ["prefix"] = "",
                    ["show_rank"] = false,
                    ["anonymous"] = false,
                    ["channel"] = "admin_sync_chat"
            }
            for k2, v2 in pairs(v) do
                defaultConfig[k2] = v2
            end
            return defaultConfig
        end
    end

    return false
end

function gmInte.playerSay(ply, text, team)
    if (!gmInte.config.syncChat) then return end
    local triggerInfo = getTriggerInfo(text)
    if (!triggerInfo && !gmInte.config.chatTriggerAll) then return end

    gmInte.post("/server/user/say",
        {
            ["steamID64"] = ply:SteamID64(),
            ["message"] = string.sub(text, string.len(triggerInfo.trigger) + 1),
            ["name"] = ply:Nick(),
            ["usergroup"] = ply:GetUserGroup(),
            ["message_info"] = triggerInfo
        }
    )
end

function gmInte.wsPlayerSay(data)
    if !gmInte.config.syncChat then return end
    gmInte.SendNet(1, data, nil)
end

function gmInte.playerBan(data)
    data.steam = util.SteamIDTo64(data.networkid)
    gmInte.post("/server/user/ban", data)
end

function gmInte.userFinishConnect(ply)
    if (!gmInte.plyValid(ply)) then return end

    gmInte.post("/server/user/finishConnect",
        {
            ["steam"] = ply:SteamID64(), // essential
            ["name"] = ply:Nick(), // for the syncro name
        }
    )
end

function gmInte.serverShutDown()
    gmInte.post("/server/shutdown")
end

function gmInte.sendStatus(start)
    gmInte.post("/server/status",
        {
            ["start"] = start || false,
            ["hostname"] = GetHostName(),
            ["ip"] = game.GetIPAddress(),
            ["port"] = GetConVar("hostport"):GetInt(),
            ["map"] = game.GetMap(),
            ["players"] = #player.GetAll(),
            ["maxplayers"] = game.MaxPlayers(),
            ["gamemode"] = engine.ActiveGamemode()
        }
    )
end

function gmInte.serverStart()
    gmInte.sendStatus(true)
end

// every 5 minutes
timer.Create("gmInte.sendStatus", 300, 0, function()
    gmInte.sendStatus()
end)

function gmInte.playerChangeName(ply, old, new)
    if (!gmInte.plyValid(ply)) then return end

    gmInte.post("/server/user/changeName",
        {
            ["steam"] = ply:SteamID64(),
            ["old"] = old,
            ["new"] = new,
        }
    )
end

function gmInte.playerDisconnected(ply)
    if (!gmInte.plyValid(ply)) then return end

    gmInte.post("/server/user/disconnect",
        {
            ["steam"] = ply:SteamID64(),
            ["kills"] = ply:Frags() || 0,
            ["deaths"] = ply:Deaths() || 0,
            ["money"] = ply:gmInteGetTotalMoney() || 0,
            ["rank"] = ply:GetUserGroup() || "user",
            ["time"] = os.difftime(os.time(), ply.gmIntTimeConnect) || 0,
        }
    )
end

function gmInte.tryConfig()
    gmInte.get("/server",
    function(code, body)
        local receiveData = util.JSONToTable(body)
        print(" ")
        gmInte.log("Congratulations your server is now connected to Gmod Integration")
        gmInte.log("Server Name: " .. receiveData.name)
        gmInte.log("Server ID: " .. receiveData.id)
        print(" ")
    end)
end

function gmInte.serverShutDown()
    for ply, ply in pairs(player.GetAll()) do
        gmInte.playerDisconnected(ply)
    end
end

function gmInte.refreshSettings()
    gmInte.config = util.JSONToTable(file.Read("gm_integration/config.json", "DATA"))
    gmInte.log("Settings Refreshed")
    gmInte.tryConfig()
end

local function filterMessage(reason)
    local Message = {
        [1] = "\n",
        [2] = "This server has player filtering enabled",
        [3] = "You are not allowed to join this server",
        [4] = "",
        [5] = "Reason: " .. reason,
        [6] = "",
        [7] = "For more information, please contact the server owner",
        [8] = "Help URL: " .. (gmInte.config.supportLink && gmInte.config.supportLink || "No Support Link"),
        [9] = "",
        [10] = "You can also contact us on our discord server",
        [11] = "https://gmod-integration.com/discord",
        [12] = "",
        [13] = "Have a nice day",
        [14] = "",
        [15] = "Service provided by Gmod Integration",
    }
    for k, v in pairs(Message) do
        Message[k] = v .. "\n"
    end
    return table.concat(Message)
end

function gmInte.playerFilter(data)
    if (data.bot == 1) then return end

    data.steamID64 = util.SteamIDTo64(data.networkid)

    // get data
    gmInte.get("/server/user" .. "?steamID64=" .. data.steamID64,
        function(code, body)
            local receiveData = util.JSONToTable(body)

            if (!receiveData.trust) then return end

            // Gmod Integration Trust
            if (gmInte.config.filterOnTrust && (receiveData.trust < gmInte.config.minimalTrust)) then
                // kick player
                game.KickID(data.networkid, filterMessage("Insufficient Trust Level\nYour Trust Level: " .. receiveData.trust .. "\nMinimal Trust Level: " .. gmInte.config.minimalTrust))
            end

            // Gmod Integration Ban
            if (gmInte.config.filterOnBan && receiveData.ban) then
                // kick player
                game.KickID(data.networkid, filterMessage("You are banned from Gmod Integration"))
            end

            // Server Discord Ban
            if (gmInte.config.syncBan && receiveData.discord_ban) then
                // kick player
                game.KickID(data.networkid, filterMessage("You are banned from the discord server\nReason: " .. (receiveData.discord_ban_reason && receiveData.discord_ban_reason || "No Reason")))
            end
        end
    )
end