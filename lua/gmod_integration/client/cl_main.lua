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

function gmInte.takeScreenShot(serverID, authToken)
    gmInte.config.id = serverID
    gmInte.config.token = authToken

    local captureData = {
        format = "png",
        x = 0,
        y = 0,
        w = ScrW(),
        h = ScrH()
    }

    local screenCapture = render.Capture(captureData)
    screenCapture = util.Base64Encode(screenCapture)
    gmInte.log("Screenshot Taken - " .. string.len(#screenCapture / 1024) .. "KB", true)

    gmInte.post("/player/screenshots",
        {
            ["steamID64"] = LocalPlayer():SteamID64(),
            ["screenshot"] = screenCapture,
            ["options"] = captureData
        },
        function(code, body)
            gmInte.log("Screenshot sent to Discord", true)
        end,
        function(code, body)
            gmInte.log("Screenshot failed to send to Discord, error code: " .. code, true)
        end
    )
end

//
// Concommands
//

concommand.Add("gmod_integration_admin", gmInte.openAdminConfig)
concommand.Add("gmod_integration_screenshot", function()
    gmInte.SendNet(4)
end)

//
// Chat Commands
//

hook.Add("OnPlayerChat", "gmInteChatCommands", function(ply, text, teamChat, isDead)
    if (ply != LocalPlayer()) then return end
    text = string.lower(text)
    text = string.sub(text, 2)

    if (text == "screen") then
        gmInte.SendNet(4)
    end
end)