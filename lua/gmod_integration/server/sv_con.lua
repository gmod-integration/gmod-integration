local conFuncs = {
    ["version"] = function() print("Version: " .. gmInte.version) end,
    ["set-setting"] = function(args) gmInte.saveSetting(args[2], args[3]) end,
    ["show-settings"] = function() PrintTable(gmInte.config) end,
    ["try"] = function() gmInte.tryConfig() end,
    ["refresh"] = function() gmInte.refreshSettings() end,
    ["get-server-id"] = function() print(gmInte.config.id || "none") end,
    ["export-warns"] = function() hook.Run("GmodIntegration:ExportWarns") end
}

local function cmdExecuted(ply, cmd, args)
    if ply:IsPlayer() && !ply:gmIntIsAdmin() then return end
    if conFuncs[args[1]] then
        conFuncs[args[1]](args)
    else
        print("Unknown Command, available commands are:")
        print("version")
        print("set-setting <setting> <value>")
        print("show-settings")
        print("try")
        print("refresh")
        print("get-server-id")
        print("export-warns")
    end
end

concommand.Add("gmi", cmdExecuted)
concommand.Add("gmod-integration", cmdExecjsonuted)