//
// Meta
//

local ply = FindMetaTable("Player")

function ply:gmIntGetConnectTime()
    return self.gmIntTimeConnect || 0
end

function ply:gmIntSetCustomValue(key, value)
    self.gmIntCustomValues = self.gmIntCustomValues || {}
    self.gmIntCustomValues[key] = value
end

function ply:gmIntGetCustomValue(key)
    return self.gmIntCustomValues && self.gmIntCustomValues[key]
end

function ply:gmIntRemoveCustomValue(key)
    if (self.gmIntCustomValues) then
        self.gmIntCustomValues[key] = nil
    end
end

//
// Compatibility
//

local function getCustomCompatability(ply)
    local values = {}

    // DarkRP
    if (DarkRP) then
        values.money = ply:getDarkRPVar("money")
        values.job = ply:getDarkRPVar("job")
    end

    // GUI Level System
    if (GUILevelSystem) then
        values.level = ply:GetLevel()
        values.xp = ply:GetXP()
    end

    return values
end

//
// Methods
//

local function getCustomValues(ply)
    local values = {}

    // Get compatability values
    for key, value in pairs(getCustomCompatability(ply)) do
        values[key] = value
    end

    // Get custom values or overwrite compatability values
    if (ply.gmIntCustomValues) then
        for key, value in pairs(ply.gmIntCustomValues) do
            values[key] = value
        end
    end

    return values
end

function ply:gmIntGetCustomValues()
    return getCustomValues(self)
end

function gmInte.plyValid(ply)
    return ply:IsValid() && ply:IsPlayer() && !ply:IsBot()
end

function gmInte.verifyPlayer(ply)
    if (!gmInte.plyValid(ply)) then return end
    gmInte.get("/players/" .. ply:SteamID64(), function(data)
        if (data.discordID && ply.gmIntUnVerified) then
            ply:Freeze(false)
            ply.gmIntUnVerified = false
        end
    end)
end

// Generate a unique token that allow player to update data link to this server (ex: screnshot, report bug, etc.)
function gmInte.getClientOneTimeToken(ply, callback)
    gmInte.get("/players/" .. ply:SteamID64() .. "/get-one-time-token", function(data)
        callback(data.token)
    end)
end

function gmInte.playerConnect(data)
    gmInte.post("/players/" .. util.SteamIDTo64(data.networkid) .. "/connect", data)
end

function gmInte.userFinishConnect(ply)
    if (!gmInte.plyValid(ply)) then return end
    ply.gmIntTimeConnect = math.Round(RealTime())

    gmInte.post("/players/" .. ply:SteamID64() .. "/finish-connect",
        {
            ["player"] = gmInte.playerFormat(ply),
        }
    )

    if (!gmInte.config.forcePlayerLink) then return end
    gmInte.get("/players/" .. ply:SteamID64(), function(data)
        if (!data.discordID) then
            ply:Freeze(true)
            ply.gmIntUnVerified = true
        end
    end)
end

function gmInte.playerDisconnected(ply)
    if (!gmInte.plyValid(ply)) then return end

    gmInte.post("/players/" .. ply:SteamID64() .. "/disconnect",
        {
            ["player"] = gmInte.playerFormat(ply),
        }
    )
end

//
// Hooks
//

hook.Add("ShutDown", "gmInte:Server:Shutdown:SavePlayers", function()
    for ply, ply in pairs(player.GetAll()) do
        gmInte.playerDisconnected(ply)
    end
end)

gameevent.Listen("player_connect")
hook.Add("player_connect", "gmInte:Player:Connect", function(data)
    gmInte.playerConnect(data)
end)

hook.Add("PlayerDisconnected", "gmInte:Player:Disconnect", function(ply)
    gmInte.playerDisconnected(ply)
end)