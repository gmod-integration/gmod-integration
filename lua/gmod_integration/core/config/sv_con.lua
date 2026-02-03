local conFuncs = {
    ["version"] = function()
        print()
        print("=== Gmod Integration Version ===")
        print("Current Version: " .. gmInte.version)
        print("================================")
        print()
    end,
    ["config"] = function(args)
        if !args[2] then
            print()
            print("[ERROR] Usage: gmi config <action>")
            print("Actions: set, show")
            print()
            return
        end

        if args[2] == "set" then
            if !args[3] || !args[4] then
                print()
                print("[ERROR] Usage: gmi config set <setting> <value>")
                print()
                return
            end

            local setting = args[3]
            local value = args[4]

            gmInte.saveSetting(setting, value)

            -- Auto-try connection if id or token was changed and both are set
            if setting == "id" && value != "" && gmInte.config.token != "" ||
               setting == "token" && value != "" && gmInte.config.id != "" then
                timer.Simple(0.5, function()
                    gmInte.tryConfig()
                end)
            end
        elseif args[2] == "show" then
            print()
            print("=== Current Config ===")
            PrintTable(gmInte.config)
            print("======================")
            print()
        elseif args[2] == "try" then
            print()
            print("=== Testing Configuration ===")
            gmInte.tryConfig()
            print("=============================")
            print()
        else
            print()
            print("[ERROR] Unknown config action: '" .. args[2] .. "'")
            print("Available actions: set, show, try")
            print()
        end
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

        print("  Server ID:          " .. (idValid && "✓ Set" || "✗ Not Set"))
        print("  Server Token:       " .. (tokenValid && "✓ Set" || "✗ Not Set"))
        print("  HTTP API:           " .. httpStatus)
        print("  WebSocket:          " .. wsStatus)

        if !idValid || !tokenValid then
            print()
            print("  [WARNING] Configure your Server ID and Token to connect")
            print("  Visit: https://gmod-integration.com/dashboard")
        end

        print()
        print("Available Commands:")
        print("  • version                            - Display current addon version")
        print("  • config set <name> <value>          - Update a configuration setting")
        print("  • config show                        - Display all current settings")
        print("  • config try                         - Test current configuration")
        print("  • export-warns                       - Export warning logs")
        print("  • help                               - Display this help message")
        print()
        print("Examples:")
        print("  gmi version")
        print("  gmi config set id YOUR_SERVER_ID")
        print("  gmi config set token YOUR_SERVER_TOKEN")
        print("  gmi config show")
        print("  gmi config try")
        print()
        print("Note: Connection is automatically tested when id or token is changed")
        print()
    end
}

local function handleMultipleCommands(ply, cmd, args)
    -- Check if there are multiple command keywords in the arguments
    local commandKeywords = {"gmi", "gmod-integration"}
    local splitIndices = {}

    -- Find all occurrences of command keywords
    for i = 1, #args do
        for _, keyword in ipairs(commandKeywords) do
            if args[i] == keyword then
                table.insert(splitIndices, i)
                break
            end
        end
    end

    -- If we found multiple command keywords, split and execute each
    if #splitIndices > 1 then
        local commands = {}

        -- Extract command groups
        for cmdIdx = 1, #splitIndices do
            local startIdx = splitIndices[cmdIdx] + 1  -- Start after the keyword
            local endIdx = (splitIndices[cmdIdx + 1] or (#args + 1)) - 1  -- End before next keyword or at end

            local commandArgs = {}
            for i = startIdx, endIdx do
                if i >= 1 && i <= #args then
                    table.insert(commandArgs, args[i])
                end
            end

            if #commandArgs > 0 then
                table.insert(commands, commandArgs)
            end
        end

        -- Execute all commands sequentially with delays
        for cmdIdx = 1, #commands do
            local delay = (cmdIdx - 1) * 0.15  -- 150ms delay between commands
            timer.Simple(delay, function()
                cmdExecuted(ply, cmd, commands[cmdIdx])
            end)
        end

        return true
    end

    return false
end

local function cmdExecuted(ply, cmd, args)
    if ply:IsPlayer() && !ply:gmIntIsAdmin() then
        print("[ERROR] You don't have permission to use this command")
        return
    end

    if !args[1] || args[1] == "help" then
        conFuncs["help"]()
        return
    end

    if args[1] == "config" then
        conFuncs["config"](args)
    elseif conFuncs[args[1]] then
        conFuncs[args[1]](args)
    else
        print()
        print("[ERROR] Unknown command: '" .. args[1] .. "'")
        print("Type 'gmi help' for a list of available commands")
        print()
    end
end

concommand.Add("gmi", function(ply, cmd, args)
    if handleMultipleCommands(ply, cmd, args) then return end
    cmdExecuted(ply, cmd, args)
end)

concommand.Add("gmod-integration", function(ply, cmd, args)
    if handleMultipleCommands(ply, cmd, args) then return end
    cmdExecuted(ply, cmd, args)
end)