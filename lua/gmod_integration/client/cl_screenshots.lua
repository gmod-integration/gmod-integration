local ScreenshotRequested = false
local FailAttempts = 0
hook.Add("PostRender", "gmInteScreenshot", function()
  if !ScreenshotRequested then return end
  local captureData = {
    format = "jpeg",
    x = 0,
    y = 0,
    w = ScrW(),
    h = ScrH(),
    quality = 95,
  }

  local screenCapture = render.Capture(captureData)
  ScreenshotRequested = false
  gmInte.showScreenshotInfo = false
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
      gmInte.chatAddText(Color(255, 255, 255), gmInte.getTranslation("chat.error.screenshot_failed", "Failed to take screenshot, your system may not support this feature."))
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
  }, function(code, body) gmInte.chatAddText(Color(255, 130, 92), gmInte.getTranslation("chat.screenshot.sent", "Screenshot sent to Discord.")) end, function(code, body) gmInte.log("Screenshot failed to send to Discord, error code: " .. code, true) end)
end)

function gmInte.takeScreenShot()
  timer.Simple(0.5, function()
    ScreenshotRequested = true
    gmInte.showScreenshotInfo = true
  end)
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

local contextMenuOpen = false
local contextClick = false
hook.Add("OnContextMenuOpen", "gmInte:ContextScreen:ContextMenu:Open", function() contextMenuOpen = true end)
hook.Add("OnContextMenuClose", "gmInte:ContextScreen:ContextMenu:Close", function() contextMenuOpen = false end)
hook.Add("HUDPaint", "gmInte:ContextScreen:Screenshot", function()
  if !contextClick then return end
  if !contextMenuOpen then return end
  surface.SetDrawColor(230, 230, 230)
  surface.DrawRect(0, 0, ScrW(), 3)
  surface.DrawRect(0, 0, 3, ScrH())
  surface.DrawRect(ScrW() - 3, 0, 3, ScrH())
  surface.DrawRect(0, ScrH() - 3, ScrW(), 3)
  surface.DrawRect(ScrW() / 2 - 10, ScrH() / 2 - 1, 20, 2)
  surface.DrawRect(ScrW() / 2 - 1, ScrH() / 2 - 10, 2, 20)
  surface.SetDrawColor(0, 0, 0, 50)
  surface.DrawRect(0, 0, ScrW(), ScrH())
  draw.SimpleText(gmInte.getTranslation("report_bug.context_menu.screen_capture", "Close the context menu to take the screenshot that will be send to Discord."), "Trebuchet24", ScrW() / 2, ScrH() / 2 + 40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

function gmInte.contextScreenshot()
  if ScreenshotRequested then return end
  contextClick = true
  local timerName = "gmInte:ContextScreen:Screenshot:Open"
  gmInte.showScreenshotInfo = true
  timer.Create(timerName, 0.2, 0, function()
    if contextMenuOpen then return end
    contextClick = false
    timer.Remove(timerName)
    timer.Simple(0.5, gmInte.takeScreenShot)
  end)
end