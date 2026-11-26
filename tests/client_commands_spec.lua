local commands, output, actions
local passes, failures = 0, {}

local function reset()
    commands, output, actions = {}, {}, {}
    print = function(message) output[#output + 1] = message end
    concommand = { Add = function(name, callback, complete, help)
        commands[name] = { callback = callback, complete = complete, help = help }
    end }
    gmInte = {
        config = { token = "synthetic-private-token-never-suggest" },
        takeScreenShot = function(title) actions[#actions + 1] = { "screenshot", title } end,
        openReportBug = function() actions[#actions + 1] = { "bug" } end,
        openAdminConfig = function() actions[#actions + 1] = { "settings" } end,
    }
    loadGLua("lua/gmod_integration/core/config/cl_commands.lua")
end

local function test(name, callback)
    reset()
    local ok, problem = pcall(callback)
    if ok then passes = passes + 1 else failures[#failures + 1] = name .. ": " .. tostring(problem) end
end

test("client tool completion exposes only static actions and handles prefixes without running anything", function()
    local command = commands.gmi_tools
    assert(command and type(command.complete) == "function" and #command.help > 0)
    assert(table.concat(command.complete("gmi_tools", " "), ",") == "gmi_tools screenshot,gmi_tools bug,gmi_tools settings")
    assert(table.concat(command.complete("gmi_tools", " SC")) == "gmi_tools screenshot")
    assert(table.concat(command.complete("GMI_TOOLS", " b")) == "GMI_TOOLS bug")
    assert(#command.complete("gmi_tools", " no-such-action") == 0)
    assert(#command.complete("gmi_tools", " screenshot some-title") == 0)
    assert(#actions == 0)
    assert(not table.concat(command.complete("gmi_tools", " ")):find(gmInte.config.token, 1, true))
end)

test("launcher delegates screenshot titles and existing guarded settings and bug functions", function()
    local run = commands.gmi_tools.callback
    run(nil, nil, { "screenshot", "My", "title" })
    run(nil, nil, { "BUG" })
    run(nil, nil, { "settings" })
    assert(#actions == 3)
    assert(actions[1][1] == "screenshot" and actions[1][2] == "My title")
    assert(actions[2][1] == "bug" and actions[3][1] == "settings")
end)

test("unknown actions or unexpected arguments print usage and have no side effects", function()
    local run = commands.gmi_tools.callback
    run(nil, nil, {})
    run(nil, nil, { "unknown" })
    run(nil, nil, { "settings", "token" })
    run(nil, nil, { "bug", "extra" })
    assert(#actions == 0 and #output == 4)
    assert(output[1]:find("Usage: gmi_tools", 1, true))
    assert(commands.gmi == nil and commands["gmod-integration"] == nil)
end)

if #failures > 0 then error(table.concat(failures, "\n")) end
io.write("Client command regressions: " .. passes .. " passed\n")
