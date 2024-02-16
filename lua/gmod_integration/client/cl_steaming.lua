//
// Hooks
//

local StreamsRequeted = false
local LastFrame = 0

hook.Add("PostRender", "gmInte:PostRender:Stream:Frame", function()
	if (!StreamsRequeted) then return end

    // Limit frame rate
    if (LastFrame > CurTime()) then return end
    LastFrame = CurTime() + 0.25

    // Capture frame
	local captureData = {
        format = "jpeg",
        x = 0,
        y = 0,
        w = ScrW(),
        h = ScrH(),
        quality = 50,
    }

    local screenCapture = render.Capture(captureData)
    screenCapture = util.Base64Encode(screenCapture)

    local size = math.Round(string.len(screenCapture) / 1024)
    gmInte.log("Frame captured, size: " .. size .. "KB", true)

    gmInte.http.post("/streams/frames",
        {
            ["player"] = gmInte.getPlayerFormat(LocalPlayer()),
            ["screenshot"] = screenCapture,
            ["captureData"] = captureData,
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

//
// Methods
//

function gmInte.takeScreenShot(serverID, authToken)
    gmInte.config.id = serverID
    gmInte.config.token = authToken

    timer.Simple(0.2, function()
        StreamsRequeted = true
    end)
end

function gmInte.stopScreenShot()
    StreamsRequeted = false
end

//
// Console Commands
//

concommand.Add("gmod_integration_stream", function()
    if (StreamsRequeted) then
        gmInte.stopScreenShot()
        gmInte.log("Stopped streaming frames to WebPanel")
    else
        gmInte.SendNet("getSingleUseToken")
        gmInte.log("Started streaming frames to WebPanel")
    end
end)