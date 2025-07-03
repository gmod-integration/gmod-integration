local function formatName(name)
    name = string.lower(name)
    name = string.upper(string.sub(name, 1, 1)) .. string.sub(name, 2)
    name = string.gsub(name, "(%a)([%w_']*)", function(a, b) return string.upper(a) .. string.lower(b) end)
    return name
end

function gmInte.discordSyncChatPly(data)
    chat.AddText(Color(92, 105, 255), "(DISCORD) ", Color(12, 151, 12), formatName(data.name) .. ": ", Color(255, 255, 255), data.content)
end