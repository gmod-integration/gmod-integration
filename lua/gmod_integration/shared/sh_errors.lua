//
// Methods
//

function gmInte.sendLuaErrorReport(err, realm, stack, name, id, uptime)
    if (name != "gmod_integration") then return end

    if (SERVER && math.Round(RealTime()) == 0) then
        return timer.Simple(1, function()
            gmInte.sendLuaErrorReport(err, realm, stack, name, id, math.Round(RealTime()))
        end)
    end

    if (CLIENT && (!IsValid(LocalPlayer()) || !gmInte.config.token)) then
        return timer.Simple(1, function()
        gmInte.sendLuaErrorReport(err, realm, stack, name, id, math.Round(RealTime()))
        end)
    end

    local endpoint = SERVER && "/servers/:serverID/errors" || "/clients/:steamID64/errors"
    gmInte.http.post(endpoint,
        {
            ["error"] = err,
            ["realm"] = realm,
            ["stack"] = stack,
            ["name"] = name,
            ["id"] = id,
            ["uptime"] = uptime || math.Round(RealTime()),
            ["identifier"] = SERVER && gmInte.config.id || LocalPlayer():SteamID64()
        }
    )
end

//
// Hooks
//

hook.Add("OnLuaError", "gmInte:OnLuaError:SendReport", function(err, realm, stack, name, id)
    gmInte.sendLuaErrorReport(err, realm, stack, name, id)
end)