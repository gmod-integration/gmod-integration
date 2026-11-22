local actions = { "screenshot", "bug", "settings" }
local help = "Usage: gmi_tools screenshot [title] | bug | settings"

local function complete(command, input)
    local text = string.lower(string.gsub(input || "", "^%s+", ""))
    local suggestions = {}
    for _, action in ipairs(actions) do
        if string.sub(action, 1, #text) == text then suggestions[#suggestions + 1] = command .. " " .. action end
    end
    return suggestions
end

local function execute(_, _, args)
    local action = string.lower(args[1] || "")
    if action == "screenshot" then
        gmInte.takeScreenShot(table.concat(args, " ", 2))
    elseif action == "bug" && !args[2] then
        gmInte.openReportBug()
    elseif action == "settings" && !args[2] then
        gmInte.openAdminConfig()
    else
        print(help)
    end
end

concommand.Add("gmi_tools", execute, complete, "Open Gmod Integration tools. Complete screenshot, bug or settings after a space.")
