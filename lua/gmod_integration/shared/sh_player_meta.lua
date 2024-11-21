local ply = FindMetaTable("Player")
function ply:gmIntGetConnectTime()
    return self.gmIntTimeConnect || 0
end

function ply:gmIntIsVerified()
    return self.gmIntVerified || false
end

function ply:gmInteGetBranch()
    return CLIENT && BRANCH || self.branch || "unknown"
end

function ply:gmIntSetCustomValue(key, value)
    self.gmIntCustomValues = self.gmIntCustomValues || {}
    self.gmIntCustomValues[key] = value
end

function ply:gmIntIsAdmin()
    return gmInte.config.adminRank[self:GetUserGroup()] || false
end

function ply:gmIntGetCustomValue(key)
    return self.gmIntCustomValues && self.gmIntCustomValues[key]
end

function ply:gmIntRemoveCustomValue(key)
    if self.gmIntCustomValues then self.gmIntCustomValues[key] = nil end
end

local function getCustomCompatability(ply)
    local values = {}
    // DarkRP
    if DarkRP then
        values.money = ply:getDarkRPVar("money")
        values.job = ply:getDarkRPVar("job")
    end

    // GUI Level System
    if GUILevelSystem then
        values.level = ply:GetLevel()
        values.xp = ply:GetXP()
    end

    // Pointshop 2
    if Pointshop2 && ply.PS2_Wallet then
        values.ps2Points = ply.PS2_Wallet.points
        values.ps2PremiumPoints = ply.PS2_Wallet.premiumPoints
    end
    return values
end

local function getCustomValues(ply)
    local values = {}
    // Get compatability values
    for key, value in pairs(getCustomCompatability(ply)) do
        values[key] = value
    end

    // Get custom values or overwrite compatability values
    if ply.gmIntCustomValues then
        for key, value in pairs(ply.gmIntCustomValues) do
            values[key] = value
        end
    end
    return values
end

function ply:gmIntGetCustomValues()
    return getCustomValues(self)
end

function ply:gmIntGetFPS()
    return self.gmIntFPS || 0
end

// Backup players before map change
hook.Add("ShutDown", "gmInte:Server:ShutDown:SavePlayer", function()
    // save in data/gm_integration/player_before_map_change.json
    local dataToSave = {
        ["version"] = "1.0",
        ["serverID"] = gmInte.config.id,
        ["playersList"] = {},
        ["sysTime"] = os.time()
    }

    if SERVER then
        for _, ply in ipairs(player.GetAll()) do
            dataToSave.playersList[ply:SteamID()] = gmInte.getPlayerFormat(ply)
        end

        if !file.Exists("gm_integration", "DATA") then file.CreateDir("gm_integration") end
        file.Write("gm_integration/player_before_map_change.json", util.TableToJSON(dataToSave, true))
    else
        dataToSave.playersList[LocalPlayer():SteamID()] = gmInte.getPlayerFormat(LocalPlayer())
        local oldData = {}
        if file.Exists("gmod_integration/player_before_map_change.json", "DATA") then oldData = util.JSONToTable(file.Read("gmod_integration/player_before_map_change.json", "DATA")) end
        oldData[gmInte.config.id] = dataToSave
        file.Write("gmod_integration/player_before_map_change.json", util.TableToJSON(oldData, true))
    end
end)

gmInte.restoreFileCache = gmInte.restoreFileCache || {}
function ply:getAjustTime()
    if SERVER then
        if table.IsEmpty(gmInte.restoreFileCache) then
            if file.Exists("gm_integration/player_before_map_change.json", "DATA") then
                gmInte.restoreFileCache = util.JSONToTable(file.Read("gm_integration/player_before_map_change.json", "DATA"))
            else
                return 0
            end
        end
    else
        if table.IsEmpty(gmInte.restoreFileCache) then
            if file.Exists("gmod_integration/player_before_map_change.json", "DATA") then
                gmInte.restoreFileCache = util.JSONToTable(file.Read("gmod_integration/player_before_map_change.json", "DATA"))
            else
                return 0
            end

            gmInte.restoreFileCache = gmInte.restoreFileCache[gmInte.config.id]
        end
    end

    if (gmInte.restoreFileCache.sysTime + 60 * 5) < (os.time() - self:gmIntGetConnectTime()) then return 0 end
    if !gmInte.restoreFileCache.playersList || !gmInte.restoreFileCache.playersList[self:SteamID()] then return 0 end
    return gmInte.restoreFileCache.playersList[self:SteamID()].connectTime || 0
end