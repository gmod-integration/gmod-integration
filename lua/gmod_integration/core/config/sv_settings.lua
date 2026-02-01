function gmInte.saveSetting(setting, value)
    if gmInte.config[setting] == nil then
        gmInte.log("Unknown Setting " .. setting)
        return
    end

    if setting == "id" || setting == "token" then gmInte.aprovedCredentials = false end
    // Boolean
    if value == "true" then value = true end
    if value == "false" then value = false end
    // Number
    if tonumber(value) != nil then value = tonumber(value) end
    gmInte.config[setting] = value
    file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
    gmInte.log("Setting Saved")
    if setting == "websocketFQDN" || setting == "id" || setting == "token" then hook.Run("GmodIntegration:Websocket:Restart") end
    if setting == "language" then gmInte.loadTranslations() end
    // send to all players the new public config
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsValid() && ply:IsPlayer(ply) then
            gmInte.log("Sending new Public Config to " .. ply:Nick(), true)
            gmInte.publicGetConfig(ply)
        end
    end
    // send new config to gmod-integration server
    local ok, err = pcall(function()
            gmInte.websocket:send("config_save", {
                data = gmInte.config
            }, nil, true)
    end)
    if !ok then
        gmInte.logError(err, true)
    end
end

function gmInte.tryConfig()
    gmInte.http.get("/servers/:serverID", function(code, body)
        print(" ")
        gmInte.log("Congratulations your server is now connected to Gmod Integration")
        gmInte.log("Server Name: " .. body.name)
        gmInte.log("Server ID: " .. body.id)
        print(" ")
    end)
end

function gmInte.testConnection(ply)
    gmInte.http.get("/servers/:serverID", function(code, body) if ply then gmInte.SendNet("testApiConnection", body, ply) end end, function(code, body) if ply then gmInte.SendNet("testApiConnection", body, ply) end end)
end

function gmInte.superadminGetConfig(ply)
    if !ply:IsValid() || !ply:IsPlayer(ply) || !ply:gmIntIsAdmin() then return end
    if !gmInte.useDataConfig then
        gmInte.SendNet("notEditableConfig", {}, ply)
        return
    end

    gmInte.config.websocket = GWSockets && true || false
    gmInte.SendNet("adminConfig", gmInte.config, ply)
end

function gmInte.publicGetConfig(ply)
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    gmInte.SendNet("publicConfig", {
        ["config"] = {
            ["id"] = gmInte.config.id,
            ["debug"] = gmInte.config.debug,
            ["apiFQDN"] = gmInte.config.apiFQDN,
            ["websocketFQDN"] = gmInte.config.websocketFQDN,
            ["adminRank"] = gmInte.config.adminRank,
            ["language"] = gmInte.config.language,
            ["clientBranch"] = gmInte.config.clientBranch,
            ["logTimestamp"] = gmInte.config.logTimestamp
        },
        ["other"] = {
            ["aprovedCredentials"] = gmInte.aprovedCredentials,
            ["version"] = gmInte.version,
        }
    }, ply)
end

function gmInte.superadminSetConfig(ply, data)
    if !ply:IsValid() || !ply:IsPlayer(ply) || !ply:gmIntIsAdmin() then return end
    for k, v in pairs(data) do
        gmInte.saveSetting(k, v)
    end

    if data.token || data.id then gmInte.testConnection(ply) end
end

hook.Add("Initialize", "gmInte:Server:Initialize:SyncConfig", function() timer.Simple(1, function()
        if (gmInte.compareVersion(gmInte.version, "5.2.0") == -1) then
            gmInte.http.post("/servers/:serverID/config", gmInte.config, function(code, body)
                gmInte.saveSetting("upgradeSyncConfig", true)
                gmInte.log("Server Config Synced with Gmod Integration")
            end, function(code, body)
                gmInte.log("Failed to Sync Server Config with Gmod Integration", true)
            end)
        end
    end)
end)