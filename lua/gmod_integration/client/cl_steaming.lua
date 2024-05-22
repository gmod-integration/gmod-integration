//
// Hooks
//

local StreamsRequeted = false
hook.Add("PostRender", "gmInte:PostRender:Stream:Frame", function()
	if (!StreamsRequeted) then return end
    StreamsRequeted = false

    // Capture frame
	local captureConfig = {
        format = "jpeg",
        x = 0,
        y = 0,
        w = ScrW(),
        h = ScrH(),
        quality = 30,
    }

    local screenCapture = render.Capture(captureConfig)
    if (!screenCapture) then return end
    screenCapture = util.Base64Encode(screenCapture)

    local size = math.Round(string.len(screenCapture) / 1024)
    gmInte.log("Frame captured, size: " .. size .. "KB", true)

    gmInte.http.post("/clients/:steamID64/servers/:serverID/streams/frames",
        {
            ["player"] = gmInte.getPlayerFormat(LocalPlayer()),
            ["base64Capture"] = screenCapture,
            ["captureConfig"] = captureConfig,
            ["size"] = size .. "KB"
        },
        function(code, body)
            gmInte.log("Frame sent to WebPanel, size: " .. size .. "KB", true)
        end,
        function(code, body)
            gmInte.log("Failed to send frame to WebPanel", true)
        end
    )
end)

local Steam = false
timer.Create("gmInte:Stream:Frame", 0.5, 0, function()
    if (Steam) then
        StreamsRequeted = true
    end
end)

//
// Console Commands
//

concommand.Add("gmod_integration_stream", function()
    Steam = !Steam
    gmInte.log("Streaming frames to WebPanel: " .. tostring(Steam))
end)