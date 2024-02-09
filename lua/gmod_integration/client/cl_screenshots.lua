//
// Hooks
//

local ScreenshotRequested = false
hook.Add("PostRender", "gmInteScreenshot", function()
	if (!ScreenshotRequested) then return end
	ScreenshotRequested = false

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

    gmInte.post("/screenshots",
        {
            ["steamID64"] = LocalPlayer():SteamID64(),
            ["screenshot"] = screenCapture,
            ["options"] = captureData,
            ["name"] = LocalPlayer():Nick()
        },
        function(code, body)
            gmInte.log("Screenshot sent to Discord", true)
        end,
        function(code, body)
            gmInte.log("Screenshot failed to send to Discord, error code: " .. code, true)
        end
    )
end)

//
// Methods
//

function gmInte.takeScreenShot(serverID, authToken)
    gmInte.config.id = serverID
    gmInte.config.token = authToken

    timer.Simple(0.2, function()
        ScreenshotRequested = true
    end)
end

//
// Console Commands
//

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