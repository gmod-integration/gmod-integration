function gmInte.getTranslation(key, default, ...)
    key = "gmod_integration." .. key
    local translation = language.GetPhrase(key)
    if translation == key then translation = default end
    if ... then
        for i = 1, select("#", ...) do
            translation = string.Replace(translation, "{" .. i .. "}", select(i, ...))
        end
    end
    return translation
end

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

function gmInte.showTestConnection(data)
    if data && data.id then
        gmInte.chatAddText(Color(89, 194, 89), gmInte.getTranslation("gmod_integration.chat.authentication_success", "Successfully Authenticated"), Color(255, 255, 255), gmInte.getTranslation("gmod_integration.chat.server_link", ", server linked as {1}.", data.name))
    else
        gmInte.chatAddText(Color(228, 81, 81), gmInte.getTranslation("gmod_integration.chat.authentication_failed", "Failed to Authenticate"), Color(255, 255, 255), gmInte.getTranslation("gmod_integration.chat.server_fail", ", check your ID and Token."))
    end
end

function gmInte.openAdminConfig()
    if !LocalPlayer():gmIntIsAdmin() then
        gmInte.chatAddText(Color(228, 81, 81), gmInte.getTranslation("chat.missing_permissions", "You do not have permission to do this action."))
        return
    end

    gmInte.SendNet("getConfig")
end