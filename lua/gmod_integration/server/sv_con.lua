local conFuncs = {
    ["version"] = function() gmInte.log("Version: " .. gmInte.version) end,
    ["setting"] = function(args) gmInte.saveSetting(args[2], args[3]) end,
    ["try"] = function() gmInte.tryConfig() end,
    ["refresh"] = function() gmInte.refreshSettings() end,
    ["get-server-id"] = function() print(gmInte.config.id || "none") end,
    ["screenshot"] = function(args)
        if !args[2] then return gmInte.log("No SteamID64 provided") end
        for _, ply in ipairs(player.GetAll()) do
            if ply:SteamID64() == args[2] then return gmInte.takeScreenshot(ply) end
        end
    end,
}

concommand.Add("gmi", function(ply, cmd, args)
    if ply:IsPlayer() && !ply:IsSuperAdmin() then return end
    if conFuncs[args[1]] then
        conFuncs[args[1]](args)
    else
        gmInte.log("Unknown Command Argument")
    end
end)