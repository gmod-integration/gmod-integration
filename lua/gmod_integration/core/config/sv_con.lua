local conFuncs = {
    ["version"] = function() 
        print()
        print("=== Gmod Integration Version ===")
        print("Current Version: " .. gmInte.version)
        print("================================")
        print()
    end,
    ["set-setting"] = function(args) 
        if !args[2] || !args[3] then
            print()
            print("[ERROR] Usage: gmi set-setting <setting> <value>")
            print()
            return
        end
        gmInte.saveSetting(args[2], args[3])
        print()
        print("[SUCCESS] Setting '" .. args[2] .. "' updated to '" .. args[3] .. "'")
        print()
    end,
    ["show-settings"] = function() 
        print()
        print("=== Current Settings ===")
        PrintTable(gmInte.config)
        print("========================")
        print()
    end,
    ["try"] = function() 
        print()
        print("=== Testing Configuration ===")
        gmInte.tryConfig()
        print("=============================")
        print()
    end,
    ["get-server-id"] = function() 
        print()
        print("=== Server Information ===")
        print("Server ID: " .. (gmInte.config.id || "Not Set"))
        print("==========================")
        print()
    end,
    ["export-warns"] = function() 
        print()
        print("=== Exporting Warnings ===")
        hook.Run("GmodIntegration:ExportWarns")
        print("==========================")
        print()
    end,
    ["help"] = function()
        print()
        print("╔════════════════════════════════════════════════════════════╗")
        print("║         Gmod Integration - Command Reference               ║")
        print("╚════════════════════════════════════════════════════════════╝")
        
        -- Connection Status
        print()
        print("Connection Status:")
        local idValid = gmInte.config.id && gmInte.config.id != ""
        local tokenValid = gmInte.config.token && gmInte.config.token != ""
        local httpStatus = gmInte.aprovedCredentials && "✓ Connected" || "✗ Disconnected"
        local wsStatus = "✗ Not Available"
        
        if GWSockets && gmInte.websocket then
            wsStatus = gmInte.websocket:isConnected() && "✓ Connected" || "✗ Disconnected"
        end
        
        print("  Server ID:     " .. (idValid && "✓ Set" || "✗ Not Set"))
        print("  Server Token:  " .. (tokenValid && "✓ Set" || "✗ Not Set"))
        print("  HTTP API:      " .. httpStatus)
        print("  WebSocket:     " .. wsStatus)
        
        if !idValid || !tokenValid then
            print()
            print("  [WARNING] Configure your Server ID and Token to connect")
            print("  Visit: https://gmod-integration.com/dashboard")
        end
        
        print()
        print("Available Commands:")
        print("  version              - Display current addon version")
        print("  set-setting          - Update a configuration setting")
        print("    Usage: gmi set-setting <name> <value>")
        print("  show-settings        - Display all current settings")
        print("  try                  - Test current configuration")
        print("  get-server-id        - Display server ID")
        print("  export-warns         - Export warning logs")
        print("  help                 - Display this help message")
        print()
        print("Examples:")
        print("  gmi version")
        print("  gmi set-setting id YOUR_SERVER_ID")
        print("  gmi set-setting token YOUR_SERVER_TOKEN")
        print("  gmi show-settings")
        print()
    end
}

local function cmdExecuted(ply, cmd, args)
    if ply:IsPlayer() && !ply:gmIntIsAdmin() then 
        print("[ERROR] You don't have permission to use this command")
        return 
    end
    
    if !args[1] || args[1] == "help" then
        conFuncs["help"]()
        return
    end
    
    if conFuncs[args[1]] then
        conFuncs[args[1]](args)
    else
        print()
        print("[ERROR] Unknown command: '" .. args[1] .. "'")
        print("Type 'gmi help' for a list of available commands")
        print()
    end
end

concommand.Add("gmi", cmdExecuted)
concommand.Add("gmod-integration", cmdExecuted)