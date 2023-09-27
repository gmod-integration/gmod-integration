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

function gmInte.discordSyncChatPly(data)
    chat.AddText(Color(92, 105, 255), "(DISCORD) ", Color(12, 151, 12), formatName(data.name) .. ": ", Color(255, 255, 255), data.content)
end