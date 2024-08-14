local ScreenshotRequested = false
local FailAttempts = 0
hook.Add("PostRender", "gmInteScreenshot", function()
  if !ScreenshotRequested then return end
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
  if !screenCapture then
    if FailAttempts < 3 then
      timer.Simple(0.5, function()
        ScreenshotRequested = true
        FailAttempts = FailAttempts + 1
        gmInte.log("Failed to take screenshot, retrying... (" .. FailAttempts .. "/3)", true)
      end)
      return
    else
      FailAttempts = 0
      chat.AddText(Color(255, 130, 92), "[Gmod Integration] ", Color(102, 63, 63), "Failed to take screenshot, your system may not support this feature.")
      return
    end
  end

  local base64Capture = util.Base64Encode(screenCapture)
  local size = math.Round(string.len(base64Capture) / 1024)
  gmInte.log("Screenshot Taken - " .. size .. "KB", true)
  gmInte.http.post("/clients/:steamID64/servers/:serverID/screenshots", {
    ["player"] = gmInte.getPlayerFormat(LocalPlayer()),
    ["screenshot"] = base64Capture,
    ["captureData"] = captureData,
    ["size"] = size .. "KB"
  }, function(code, body)
    gmInte.log("Screenshot sent to Discord", true)
    chat.AddText(Color(255, 130, 92), "[Gmod Integration] ", Color(255, 255, 255), "Screenshot sent to Discord.")
  end, function(code, body) gmInte.log("Screenshot failed to send to Discord, error code: " .. code, true) end)
end)

function gmInte.takeScreenShot()
  timer.Simple(0.5, function() ScreenshotRequested = true end)
end

concommand.Add("gmi_screen", gmInte.takeScreenShot)
concommand.Add("gmod_integration_screen", gmInte.takeScreenShot)
hook.Add("OnPlayerChat", "gmInteChatCommands", function(ply, text, teamChat, isDead)
  if ply != LocalPlayer() then return end
  text = string.lower(text)
  text = string.sub(text, 2)
  if text == "screen" then
    gmInte.takeScreenShot()
    return true
  end
end)