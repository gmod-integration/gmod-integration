local conFuncs = {
    ["version"] = function() gmInte.log("Version: " .. gmInte.version) end,
    ["setting"] = function(args) gmInte.saveSetting(args[2], args[3]) end,
    ["try"] = function() gmInte.tryConfig() end,
    ["refresh"] = function() gmInte.refreshSettings() end,
    ["get-server-id"] = function() print(gmInte.config.id || "none") end,
    ["export-warns"] = function() hook.Run("GmodIntegration:ExportWarns") end
}

local function cmdExecuted(ply, cmd, args)
    if ply:IsPlayer() && !ply:IsSuperAdmin() then return end
    if conFuncs[args[1]] then
        conFuncs[args[1]](args)
    else
        gmInte.log("Unknown Command Argument")
    end
end

concommand.Add("gmi", cmdExecuted)
concommand.Add("gmod-integration", cmdExecjsonuted)