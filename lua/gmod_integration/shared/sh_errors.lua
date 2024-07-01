//
// Methods
//

local cacheErrors = {}

function gmInte.sendLuaErrorReport(err, realm, stack, name, id)
    cacheErrors[err] = {
        ["time"] = CurTime(),
        ["count"] = cacheErrors[err] && cacheErrors[err].count + 1 || 1,
    }

    if (!gmInte.config.id || !gmInte.config.token) then return end
    if (CLIENT && !IsValid(LocalPlayer())) then return end

    local count = cacheErrors[err].count
    timer.Simple(0.5, function()
        if (cacheErrors[err].count != count) then
            if (cacheErrors[err].count == 100) then
            else
                return
            end
        else
            cacheErrors[err] = nil
        end

        local endpoint = SERVER && "/servers/:serverID/errors" || "/clients/:steamID64/servers/:serverID/errors"
        gmInte.http.post(endpoint,
            {
                ["error"] = err,
                ["realm"] = realm,
                ["stack"] = stack,
                ["name"] = name,
                ["id"] = id,
                ["count"] = count,
                ["uptime"] = math.Round(RealTime()),
                ["identifier"] = SERVER && gmInte.config.id || CLIENT && LocalPlayer():SteamID64()
            }
        )
    end)
end

//
// Hooks
//

hook.Add("OnLuaError", "gmInte:OnLuaError:SendReport", function(err, realm, stack, name, id)
    gmInte.sendLuaErrorReport(err, realm, stack, name, id)
end)