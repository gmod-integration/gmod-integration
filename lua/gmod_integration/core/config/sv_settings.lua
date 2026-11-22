local booleanSettings = {
    syncBan = true, syncTimeout = true, syncKick = true, filterOnBan = true,
    redownloadMaterials = true, debug = true, forcePlayerLink = true, verifyOnJoin = true,
    verifyFamilySharing = true, maintenance = true,
}
local localSettings = { id = true, token = true, websocketFQDN = true, apiFQDN = true }
local syncing = false
local configRevision = 0
local configNeedsSync = false
local savingConfig = false
local languages = { en = true, fr = true, de = true, es = true, it = true, tr = true, ru = true }

local function normalizeSetting(setting, value)
    if booleanSettings[setting] then
        if value == "true" then value = true end
        if value == "false" then value = false end
        return isbool(value), value
    elseif setting == "verifyOnReadyKickTime" then
        local number = tonumber(value)
        return number != nil && number == number && number >= 0 && number <= 2147483647 && number % 1 == 0, number
    elseif setting == "adminRank" then
        if isstring(value) then
            local ok, decoded = pcall(util.JSONToTable, value)
            if !ok then return false end
            value = decoded
        end
        if !istable(value) then return false end
        local count = 0
        local ranks = {}
        for rank, enabled in pairs(value) do
            count = count + 1
            if count > 64 || !isstring(rank) || #rank < 1 || #rank > 64 || !isbool(enabled) then return false end
            if enabled then ranks[rank] = true end
        end
        if next(ranks) == nil then return false end
        local encoded = util.TableToJSON(ranks)
        return isstring(encoded) && #encoded <= 255, ranks
    elseif setting == "clientBranch" then
        return value == "any" || value == "none" || value == "dev" || value == "prerelease" || value == "x86-64", value
    elseif setting == "language" then
        return isstring(value) && languages[value] == true, value
    elseif setting == "supportLink" then
        return isstring(value) && #value <= 255 && !string.find(value, "\0", 1, true) &&
            (value == "" || string.match(value, "^https?://[^%s]+$") != nil), value
    elseif setting == "logTimestamp" then
        return isstring(value) && #value <= 255 && !string.find(value, "\0", 1, true), value
    elseif setting == "id" then
        -- Server IDs and credentials must never pass through tonumber: snowflakes exceed Lua's exact integer range.
        return isstring(value) && #value <= 96 && (value == "" || string.match(value, "^[%w%-]+$") != nil), value
    elseif setting == "token" then
        return isstring(value) && #value <= 1024 && !string.find(value, "[%c]"), value
    elseif setting == "websocketFQDN" || setting == "apiFQDN" then
        return isstring(value) && #value > 0 && #value <= 255 && string.match(value, "^[%w%.%-%:%[%]]+$") != nil, value
    end
    return false
end

function gmInte.validateRemoteSetting(setting, value)
    if !isstring(setting) then return false end
    setting = string.gsub(setting, "^ig_", "")
    if localSettings[setting] then return false end
    return normalizeSetting(setting, value)
end

local function syncedSettings()
    local settings = {}
    for setting, value in pairs(gmInte.config) do
        local valid, normalized = normalizeSetting(setting, value)
        if !localSettings[setting] && valid then settings[setting] = normalized end
    end
    return settings
end

local function pushConfig()
    if savingConfig || !gmInte.aprovedCredentials then return end
    local revision = configRevision
    savingConfig = true
    gmInte.api.post("/servers/:serverID/config", syncedSettings(), function()
        savingConfig = false
        if revision == configRevision then
            configNeedsSync = false
        else
            pushConfig()
        end
    end, function()
        savingConfig = false
        gmInte.logWarning("Configuration is saved locally; remote synchronization could not be confirmed", true)
    end)
end

local function persist()
    file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
end

local function broadcastPublicConfig()
    for _, ply in ipairs(player.GetAll()) do
        if IsValid(ply) && ply:IsPlayer() then gmInte.publicGetConfig(ply) end
    end
end

function gmInte.saveSetting(setting, value)
    if !isstring(setting) || gmInte.config[setting] == nil then return false end
    local valid, normalized = normalizeSetting(setting, value)
    if !valid then
        gmInte.logWarning("Rejected an invalid configuration value", true)
        return false
    end
    if gmInte.config[setting] == normalized then return true end
    gmInte.config[setting] = normalized
    persist()
    if setting == "language" then gmInte.loadTranslations() end
    if localSettings[setting] && setting != "apiFQDN" then
        gmInte.aprovedCredentials = false
        hook.Run("GmodIntegration:Websocket:Restart")
    end
    broadcastPublicConfig()
    if !syncing && !localSettings[setting] then
        configRevision = configRevision + 1
        configNeedsSync = true
        pushConfig()
    end
    return true
end

function gmInte.tryConfig()
    gmInte.api.get("/servers/:serverID", function(_, body)
        gmInte.log("Your server is connected to Gmod Integration using WebSocket")
        if istable(body) && isstring(body.name) then gmInte.log("Server Name: " .. body.name) end
    end, function(_, body)
        gmInte.logWarning("Connection could not be confirmed. Check your credentials and the WebSocket connection.")
    end)
end

function gmInte.testConnection(ply)
    if !IsValid(ply) || !ply:IsPlayer() || !ply:gmIntIsAdmin() then return end
    local function reply(body)
        if !IsValid(ply) || !ply:IsPlayer() || !ply:gmIntIsAdmin() then return end
        local result = { error = "connection_failed" }
        if istable(body) && isstring(body.id) && #body.id > 0 && #body.id <= 96 then
            result = { id = body.id }
            if isstring(body.name) && #body.name <= 255 then result.name = body.name end
        end
        gmInte.SendNet("testApiConnection", result, ply)
    end
    gmInte.api.get("/servers/:serverID", function(_, body) reply(body) end, function() reply(nil) end)
end

function gmInte.getConfigSnapshot()
    local settings = {}
    for setting, value in pairs(gmInte.config) do
        local valid, normalized = normalizeSetting(setting, value)
        if setting != "token" && valid then settings[setting] = normalized end
    end
    settings.tokenConfigured = isstring(gmInte.config.token) && gmInte.config.token != ""
    settings.websocket = GWSockets && true || false
    return settings
end

function gmInte.superadminGetConfig(ply)
    if !IsValid(ply) || !ply:IsPlayer() || !ply:gmIntIsAdmin() then return end
    if !gmInte.useDataConfig then
        gmInte.SendNet("notEditableConfig", {}, ply)
        return
    end
    gmInte.SendNet("adminConfig", gmInte.getConfigSnapshot(), ply)
end

function gmInte.publicGetConfig(ply)
    if !IsValid(ply) || !ply:IsPlayer() then return end
    gmInte.SendNet("publicConfig", {
        config = {
            id = gmInte.config.id, debug = gmInte.config.debug,
            apiFQDN = gmInte.config.apiFQDN, websocketFQDN = gmInte.config.websocketFQDN,
            adminRank = gmInte.config.adminRank, language = gmInte.config.language,
            clientBranch = gmInte.config.clientBranch, logTimestamp = gmInte.config.logTimestamp,
        },
        other = { aprovedCredentials = gmInte.aprovedCredentials, version = gmInte.version },
    }, ply)
end

function gmInte.superadminSetConfig(ply, data)
    if !IsValid(ply) || !ply:IsPlayer() || !ply:gmIntIsAdmin() || !istable(data) then return end
    local count = 0
    for setting, value in pairs(data) do
        count = count + 1
        if count > 32 || !isstring(setting) || !normalizeSetting(setting, value) then return end
    end
    for setting, value in pairs(data) do gmInte.saveSetting(setting, value) end
    if data.token != nil || data.id != nil then gmInte.testConnection(ply) end
end

function gmInte.wsEditSetting(data)
    if !istable(data) || !gmInte.validateRemoteSetting(data.setting, data.value) then return end
    syncing = true
    local ok = pcall(gmInte.saveSetting, string.gsub(data.setting, "^ig_", ""), data.value)
    syncing = false
    if !ok then gmInte.logError("Remote configuration update failed", true) end
end

local function syncConfig()
    if configNeedsSync then pushConfig() return end
    if gmInte.compareVersion(gmInte.previusVersion || "0.0.0", "5.2.2") == -1 && !gmInte.config.upgradeSyncConfig then
        gmInte.api.post("/servers/:serverID/config", syncedSettings(), function()
            gmInte.config.upgradeSyncConfig = true
            persist()
        end, function() gmInte.logWarning("Initial configuration synchronization failed", true) end)
        return
    end
    local revision = configRevision
    gmInte.api.get("/servers/:serverID/config", function(_, body)
        if !istable(body) || revision != configRevision then return end
        local settings = istable(body.settings) && body.settings || body
        syncing = true
        local ok = pcall(function()
            for key, value in pairs(settings) do
                if isstring(key) && gmInte.validateRemoteSetting(key, value) then
                    gmInte.saveSetting(string.gsub(key, "^ig_", ""), value)
                end
            end
        end)
        syncing = false
        if !ok then gmInte.logError("Configuration synchronization failed", true) end
    end, function() gmInte.logWarning("Remote configuration could not be loaded; local settings are preserved", true) end)
end

hook.Add("GmodIntegration:Websocket:Ready", "gmInte:WebSocket:SyncConfig", function()
    broadcastPublicConfig()
    syncConfig()
end)
