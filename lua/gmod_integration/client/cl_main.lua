//
// Main
//

local function formatName(name)
    // all un down case
    name = string.lower(name)
    // first leter in upper case
    name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
    // every letter after a space in upper case
    name = string.gsub(name, "(%a)([%w_']*)", function(a,b) return string.upper(a) .. string.lower(b) end)
    return name
end

function gmInte.chatAddText(data)
    local args = {}
    for _, v in ipairs(data) do
        table.insert(args, v.color)
        table.insert(args, v.text)
    end
    chat.AddText(unpack(args))
end

function gmInte.discordSyncChatPly(data)
    chat.AddText(Color(92, 105, 255), "(DISCORD) ", Color(12, 151, 12), formatName(data.name) .. ": ", Color(255, 255, 255), data.content)
end

function gmInte.showTestConnection(data)
    if (data && data.id) then
        chat.AddText(Color(255, 130, 92), "[Gmod Integration] ", Color(63, 102, 63), "Connection Successfull", Color(255, 255, 255), ", server logged as '" .. data.name .. "'")
    else
        chat.AddText(Color(255, 130, 92), "[Gmod Integration] ", Color(102, 63, 63), "Connection Failed", Color(255, 255, 255), ", please check your ID and Token")
    end
end

function gmInte.openAdminConfig()
    if (!LocalPlayer():IsSuperAdmin()) then
        chat.AddText(Color(255, 130, 92), "[Gmod Integration] ", Color(102, 63, 63), "You are not superadmin")
        return
    end

    gmInte.SendNet(2)
end

//
// Concommands
//

concommand.Add("gmod_integration_admin", gmInte.openAdminConfig)