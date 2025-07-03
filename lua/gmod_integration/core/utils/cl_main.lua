function gmInte.chatAddText(...)
    local args = {...}
    table.insert(args, 1, Color(255, 130, 92))
    table.insert(args, 2, "[Gmod Integration] ")
    chat.AddText(unpack(args))
end

function gmInte.chatAddTextFromTable(data)
    local args = {}
    for _, v in ipairs(data) do
        table.insert(args, v.color || Color(255, 255, 255))
        table.insert(args, v.text)
    end

    gmInte.chatAddText(unpack(args))
end