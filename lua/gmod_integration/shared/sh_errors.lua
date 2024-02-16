//
// Methods
//

function gmInte.sendLuaErrorReport(err, realm, stack, name, id)
    if (name != "gmod_integration") then return end
    if (SERVER && math.Round(RealTime()) == 0) then return end

    gmInte.http.post("/errors",
        {
            ["error"] = err,
            ["realm"] = realm,
            ["stack"] = stack,
            ["name"] = name,
            ["id"] = id,
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