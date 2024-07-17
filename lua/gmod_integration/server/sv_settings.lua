function gmInte.saveSetting(setting, value)
    if gmInte.config[setting] == nil then
        gmInte.log("Unknown Setting")
        return
    end

    // Boolean
    if value == "true" then value = true end
    if value == "false" then value = false end
    // Number
    if tonumber(value) != nil then value = tonumber(value) end
    gmInte.config[setting] = value
    file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
    gmInte.log("Setting Saved")
    if value == "websocketFQDN" || value == "id" || value == "token" then gmInte.resetWebSocket() end
    // send to all players the new public config
    for _, ply in ipairs(player.GetAll()) do
        if ply:IsValid() && ply:IsPlayer(ply) then
            gmInte.log("Sending new Public Config to " .. ply:Nick(), true)
            gmInte.publicGetConfig(ply)
        end
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

function gmInte.refreshSettings()
    gmInte.config = util.JSONToTable(file.Read("gm_integration/config.json", "DATA"))
    gmInte.log("Settings Refreshed")
    gmInte.tryConfig()
end

function gmInte.superadminGetConfig(ply)
    if !ply:IsValid() || !ply:IsPlayer(ply) || !ply:IsSuperAdmin() then return end
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
        },
        ["other"] = {
            ["aprovedCredentials"] = gmInte.aprovedCredentials,
            ["version"] = gmInte.version,
        }
    }, ply)
end

function gmInte.superadminSetConfig(ply, data)
    if !ply:IsValid() || !ply:IsPlayer(ply) || !ply:IsSuperAdmin() then return end
    for k, v in ipairs(data) do
        gmInte.saveSetting(k, v)
    end

    if data.token || data.id then gmInte.testConnection(ply) end
end