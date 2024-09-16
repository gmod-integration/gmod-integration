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
        gmInte.chatAddText(Color(89, 194, 89), gmInte.getTranslation("chat.authentication_success", "Successfully Authenticated"), Color(255, 255, 255), gmInte.getTranslation("chat.server_link", ", server linked as {1}.", data.name))
    else
        gmInte.chatAddText(Color(228, 81, 81), gmInte.getTranslation("chat.authentication_failed", "Failed to Authenticate"), Color(255, 255, 255), gmInte.getTranslation("chat.server_fail", ", check your ID and Token."))
    end
end

function gmInte.openAdminConfig()
    if !LocalPlayer():gmIntIsAdmin() then
        gmInte.chatAddText(Color(228, 81, 81), gmInte.getTranslation("chat.missing_permissions", "You do not have permission to do this action."))
        return
    end

    gmInte.SendNet("getConfig")
end

hook.Add("HUDPaint", "gmInte:HUD:ShowScreenshotInfo", function()
    if !gmInte.showScreenshotInfo then return end
    local screenInfo = {
        {
            txt = "Server ID",
            val = gmInte.config.id
        },
        {
            txt = "SteamID64",
            val = LocalPlayer():SteamID64()
        },
        {
            txt = "Date",
            val = os.date("%Y-%m-%d %H:%M:%S")
        },
        {
            txt = "Position",
            val = function()
                local pos = LocalPlayer():GetPos()
                local newPos = ""
                for i = 1, 3 do
                    newPos = newPos .. math.Round(pos[i])
                    if i < 3 then newPos = newPos .. ", " end
                end
                return newPos
            end
        },
        {
            txt = "Map",
            val = game.GetMap()
        },
        {
            txt = "Ping",
            val = LocalPlayer():Ping()
        },
        {
            txt = "FPS",
            val = function() return math.Round(1 / FrameTime()) end
        },
        {
            txt = "Size",
            val = ScrW() .. "x" .. ScrH()
        }
    }

    local concatInfo = ""
    for k, v in pairs(screenInfo) do
        local val = v.val
        if type(val) == "function" then val = val() end
        concatInfo = concatInfo .. v.txt .. ": " .. val
        if k < #screenInfo then concatInfo = concatInfo .. " - " end
    end

    draw.SimpleText(concatInfo, "DermaDefault", ScrW() / 2, ScrH() - 15, Color(255, 255, 255, 119), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)