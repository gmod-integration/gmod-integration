function gmInte.chatAddText(data)
    local args = {}
    for _, v in pairs(data) do
        table.insert(args, v.color)
        table.insert(args, v.text)
    end

    chat.AddText(unpack(args))
end

function gmInte.showTestConnection(data)
    if data && data.id then
        chat.AddText(Color(255, 130, 92), "[Gmod Integration] ", Color(63, 102, 63), "Connection Successfull", Color(255, 255, 255), ", server logged as '" .. data.name .. "'")
    else
        chat.AddText(Color(255, 130, 92), "[Gmod Integration] ", Color(102, 63, 63), "Connection Failed", Color(255, 255, 255), ", please check your ID and Token")
    end
end

function gmInte.openAdminConfig()
    if !ply:gmIntIsAdmin() then
        chat.AddText(Color(255, 130, 92), "[Gmod Integration] ", Color(102, 63, 63), "You are not superadmin")
        return
    end

    gmInte.SendNet("getConfig")
end