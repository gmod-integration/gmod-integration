//
// Functions
//

// Meta
local ply = FindMetaTable("Player")

function ply:gmInteGetTotalMoney()
    // if darkrp
    if DarkRP then
        return self:getDarkRPVar("money")
    end

    // else
    return 0
end

// Main
function gmInte.removePort(ip)
    return string.Explode(":", ip)[1]
end

function gmInte.plyValid(ply)
    return ply:IsValid() && ply:IsPlayer() && !ply:IsBot()
end

function gmInte.saveSetting(setting, value)
    // save this in data/gmod_integration/setting.json but first check if variable is valid
    if !gmInte.config[setting] then
        gmInte.log("Unknown Setting")
        return
    end

    gmInte.config[setting] = value
    file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
    gmInte.log("Setting Saved")
end

function gmInte.playerConnect(data)
    if (data.bot == 1) then return end
    data.steam = util.SteamIDTo64(data.networkid)

    gmInte.post("/server/user/connect", data)
end

local function triggerChat(text)
    for k, v in pairs(gmInte.config.chatTrigger) do
        if (string.StartWith(text, k)) then return true end
    end

    return false
end

function gmInte.playerSay(ply, text, team)
    if (!gmInte.config.syncChat) then return end
    if (!triggerChat(text) && !gmInte.config.chatTriggerAll) then return end

    gmInte.post("/server/user/say",
        {
            ["steamID64"] = ply:SteamID64(),
            ["message"] = text
        }
    )
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

function gmInte.sendStatus()
    gmInte.post("/server/status",
        {
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
            ["money"] = ply:gmInteGetTotalMoney(),
            ["rank"] = ply:GetUserGroup() || "user",
        }
    )
end

function gmInte.tryConfig()
    gmInte.post("/server/guild", {},
    function( body, length, headers, code)
        gmInte.log("GG you are authorized, the link discord guild is: " .. body)
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