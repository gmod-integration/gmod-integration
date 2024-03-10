//
// Hooks
//

local ScreenshotRequested = false
hook.Add("PostRender", "gmInteScreenshot", function()
	if (!ScreenshotRequested) then return end
	ScreenshotRequested = false

	local captureData = {
        format = "jpeg",
        x = 0,
        y = 0,
        w = ScrW(),
        h = ScrH(),
        quality = 95,
    }

    local screenCapture = render.Capture(captureData)
    if (!screenCapture) then
        chat.AddText(Color(255, 130, 92), "[Gmod Integration] ", Color(102, 63, 63), "Failed to take screenshot, your system may not support this feature.")
        return
    end

    screenCapture = util.Base64Encode(screenCapture)

    local size = math.Round(string.len(screenCapture) / 1024)
    gmInte.log("Screenshot Taken - " .. size .. "KB", true)

    gmInte.http.post("/screenshots",
        {
            ["player"] = gmInte.getPlayerFormat(LocalPlayer()),
            ["screenshot"] = screenCapture,
            ["captureData"] = captureData,
            ["size"] = size .. "KB"
        },
        function(code, body)
            gmInte.log("Screenshot sent to Discord", true)
            chat.AddText(Color(255, 130, 92), "[Gmod Integration] ", Color(255, 255, 255), "Screenshot sent to Discord.")
        end,
        function(code, body)
            gmInte.log("Screenshot failed to send to Discord, error code: " .. code, true)
        end
    )
end)

//
// Methods
//

function gmInte.takeScreenShot()
    ScreenshotRequested = true
end

//
// Console Commands
//

concommand.Add("gmod_integration_screenshot", function()
    gmInte.takeScreenShot()
end)

//
// Chat Commands
//

hook.Add("OnPlayerChat", "gmInteChatCommands", function(ply, text, teamChat, isDead)
    if (ply != LocalPlayer()) then return end
    text = string.lower(text)
    text = string.sub(text, 2)

    if (text == "screen") then
        gmInte.takeScreenShot()
        return true
    end
end)