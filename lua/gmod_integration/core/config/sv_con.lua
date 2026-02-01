local conFuncs = {
    ["version"] = function() 
        print("\n=== Gmod Integration Version ===")
        print("Current Version: " .. gmInte.version)
        print("================================\n")
    end,
    ["set-setting"] = function(args) 
        if !args[2] || !args[3] then
            print("\n[ERROR] Usage: gmi set-setting <setting> <value>\n")
            return
        end
        gmInte.saveSetting(args[2], args[3])
        print("\n[SUCCESS] Setting '" .. args[2] .. "' updated to '" .. args[3] .. "'\n")
    end,
    ["show-settings"] = function() 
        print("\n=== Current Settings ===")
        PrintTable(gmInte.config)
        print("========================\n")
    end,
    ["try"] = function() 
        print("\n=== Testing Configuration ===")
        gmInte.tryConfig()
        print("=============================\n")
    end,
    ["get-server-id"] = function() 
        print("\n=== Server Information ===")
        print("Server ID: " .. (gmInte.config.id || "Not Set"))
        print("==========================\n")
    end,
    ["export-warns"] = function() 
        print("\n=== Exporting Warnings ===")
        hook.Run("GmodIntegration:ExportWarns")
        print("==========================\n")
    end,
    ["help"] = function()
        print("\n╔════════════════════════════════════════════════════════════╗")
        print("║         Gmod Integration - Command Reference               ║")
        print("╚════════════════════════════════════════════════════════════╝")
        
        -- Connection Status
        print("\n🔌 Connection Status:")
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
            print("\n  ⚠️  Configure your Server ID and Token to connect")
            print("     Visit: https://gmod-integration.com/dashboard")
        end
        
        print("\n📋 Available Commands:")
        print("  • version              - Display current addon version")
        print("  • set-setting          - Update a configuration setting")
        print("    Usage: gmi set-setting <name> <value>")
        print("  • show-settings        - Display all current settings")
        print("  • try                  - Test current configuration")
        print("  • get-server-id        - Display server ID")
        print("  • export-warns         - Export warning logs")
        print("  • reload-config        - Reload configuration from file")
        print("  • status               - Show addon status and health")
        print("  • help                 - Display this help message")
        print("\n💡 Examples:")
        print("  gmi version")
        print("  gmi set-setting id YOUR_SERVER_ID")
        print("  gmi set-setting token YOUR_SERVER_TOKEN")
        print("  gmi show-settings\n")
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
        print("\n[ERROR] Unknown command: '" .. args[1] .. "'")
        print("Type 'gmi help' for a list of available commands\n")
    end
end

concommand.Add("gmi", cmdExecuted)
concommand.Add("gmod-integration", cmdExecuted)