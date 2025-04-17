local cacheErrors = {}
function gmInte.sendLuaErrorReport(err, realm, stack, name, id)
    local count = cacheErrors[err] && cacheErrors[err].count + 1 || 1
    cacheErrors[err] = {
        ["time"] = CurTime(),
        ["count"] = count,
    }

    if !gmInte.config.id || !gmInte.config.token then return end
    if CLIENT && !IsValid(LocalPlayer()) then return end
    timer.Simple(0.5, function()
        if !cacheErrors[err] then return end
        if cacheErrors[err].count != count then
            if cacheErrors[err].count != 100 then return end
        else
            cacheErrors[err] = nil
        end

        local endpoint = SERVER && "/servers/:serverID/errors" || "/clients/:steamID64/servers/:serverID/errors"
        gmInte.http.post(endpoint, {
            ["error"] = err,
            ["realm"] = realm,
            ["stack"] = stack,
            ["name"] = name,
            ["id"] = id,
            ["count"] = count,
            ["uptime"] = math.Round(RealTime()),
            ["identifier"] = SERVER && gmInte.config.id || CLIENT && LocalPlayer():SteamID64()
        })
    end)
end

hook.Add("OnLuaError", "gmInte:OnLuaError:SendReport", function(err, realm, stack, name, id) gmInte.sendLuaErrorReport(err, realm, stack, name, id) end)