local Fields = {
  {
    ["title"] = gmInte.getTranslation("report_bug.screenshot", "Screenshot"),
    ["type"] = "image",
  },
  {
    ["title"] = gmInte.getTranslation("report_bug.description", "Report a bug to the developers of this game."),
    ["type"] = "text",
    ["dsc"] = gmInte.getTranslation("report_bug.description.dsc", "Please provide as much information as possible to help us fix the issue."),
    ["tall"] = 80,
  },
  {
    ["title"] = gmInte.getTranslation("report_bug.importance_level", "Importance Level"),
    ["type"] = "dropdown",
    ["options"] = {
      {
        ["level"] = "critical",
        ["text"] = gmInte.getTranslation("report_bug.importance_level.critical", "Critical - Crash or made the game unplayable."),
      },
      {
        ["level"] = "high",
        ["text"] = gmInte.getTranslation("report_bug.importance_level.high", "High - Critical functionality is unusable."),
      },
      {
        ["level"] = "medium",
        ["text"] = gmInte.getTranslation("report_bug.importance_level.medium", "Medium - Important functionality is unusable."),
      },
      {
        ["level"] = "low",
        ["text"] = gmInte.getTranslation("report_bug.importance_level.low", "Low - Cosmetic issue."),
      },
      {
        ["level"] = "trivial",
        ["text"] = gmInte.getTranslation("report_bug.importance_level.trivial", "Trivial - Very minor issue."),
      }
    },
  },
  {
    ["title"] = gmInte.getTranslation("report_bug.steps_to_reproduce", "Steps to Reproduce"),
    ["type"] = "text",
    ["dsc"] = gmInte.getTranslation("report_bug.steps_to_reproduce.dsc", "Please provide a step-by-step guide on how to reproduce the bug."),
    ["tall"] = 80,
  },
  {
    ["title"] = gmInte.getTranslation("report_bug.expected_result", "Expected result"),
    ["type"] = "text",
    ["dsc"] = gmInte.getTranslation("report_bug.expected_result.dsc", "What did you expect to happen?"),
    ["tall"] = 50,
  },
  {
    ["title"] = gmInte.getTranslation("report_bug.actual_result", "Actual result"),
    ["type"] = "text",
    ["dsc"] = gmInte.getTranslation("report_bug.actual_result.dsc", "What actually happened?"),
    ["tall"] = 50,
  },
}

local ScreenshotRequested = false
local contextMenuOpen = false
hook.Add("OnContextMenuOpen", "gmInte:BugReport:ContextMenu:Open", function() contextMenuOpen = true end)
hook.Add("OnContextMenuClose", "gmInte:BugReport:ContextMenu:Close", function() contextMenuOpen = false end)
hook.Add("HUDPaint", "gmInte:BugReport:Screenshot", function()
  if !ScreenshotRequested then return end
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
  draw.SimpleText(gmInte.getTranslation("report_bug.context_menu.screen_capture", "Close the context menu to take the screenshot to use in the bug report."), "Trebuchet24", ScrW() / 2, ScrH() / 2 + 40, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

local screenCapture = nil
local screenFileID = nil
local captureData = nil
hook.Add("PostRender", "gmInte:BugReport:Screenshot", function()
  if !ScreenshotRequested then return end
  if contextMenuOpen then return end
  captureData = {
    format = "jpeg",
    x = 0,
    y = 0,
    w = ScrW(),
    h = ScrH(),
    quality = 95,
  }

  screenCapture = render.Capture(captureData)
  ScreenshotRequested = false
  gmInte.showScreenshotInfo = false
  if !file.Exists("gmod_integration/report_bug", "DATA") then file.CreateDir("gmod_integration/report_bug") end
  if screenCapture then file.Write("gmod_integration/report_bug/" .. screenFileID .. ".jpeg", screenCapture) end
end)

local function openReportBug()
  local frame = vgui.Create("DFrame")
  frame:SetSize(500, (700 / 1080) * ScrH())
  frame:Center()
  frame:SetTitle(gmInte.getFrameName(gmInte.getTranslation("report_bug.title", "Report Bug")))
  frame:MakePopup()
  gmInte.applyPaint(frame)
  local dPanel = vgui.Create("DScrollPanel", frame)
  dPanel:Dock(FILL)
  gmInte.applyPaint(dPanel)
  local label = vgui.Create("DLabel", dPanel)
  label:Dock(TOP)
  label:DockMargin(5, 5, 5, 5)
  label:SetText(gmInte.getTranslation("report_bug.description", "Description"))
  label:SetFont("DermaDefaultBold")
  local messagePanel = vgui.Create("DPanel", dPanel)
  messagePanel:Dock(TOP)
  messagePanel:SetTall(70)
  messagePanel:DockMargin(5, 0, 5, 5)
  messagePanel:SetBackgroundColor(Color(0, 0, 0, 0))
  local messageLabel = vgui.Create("DLabel", messagePanel)
  messageLabel:Dock(FILL)
  messageLabel:SetText(gmInte.getTranslation("gmod_integration.report_bug.description.full", "Hey, your about to report a bug to the owners of this server.\nPlease provide as much information as possible to help us fix the issue.\nThank you for helping us improve the server.\n\nIf you have a issue with Gmod Integration, please use our discord server."))
  messageLabel:SetWrap(true)
  local elements = {}
  for _ = 1, #Fields do
    local field = Fields[_]
    local label = vgui.Create("DLabel", dPanel)
    label:Dock(TOP)
    label:DockMargin(5, 5, 5, 5)
    label:SetText(field.title)
    label:SetFont("DermaDefaultBold")
    if field.type == "image" then
      if !screenCapture then continue end
      if !file.Exists("gmod_integration/report_bug/" .. screenFileID .. ".jpeg", "DATA") then continue end
      local image = vgui.Create("DImage", dPanel)
      image:Dock(TOP)
      image:DockMargin(5, 5, 5, 5)
      image:SetImage("data/gmod_integration/report_bug/" .. screenFileID .. ".jpeg")
      image:SetSize(frame:GetWide() - 10, (frame:GetWide() - 10) * (9 / 16))
    elseif field.type == "text" then
      local text = vgui.Create("DTextEntry", dPanel)
      text:Dock(TOP)
      text:DockMargin(5, 5, 5, 5)
      text:SetMultiline(true)
      text:SetTall(field.tall || 40)
      text:SetPlaceholderText(field.dsc)
      gmInte.applyPaint(text)
      table.insert(elements, text)
    elseif field.type == "dropdown" then
      local dropdown = vgui.Create("DComboBox", dPanel)
      dropdown:Dock(TOP)
      dropdown:SetSortItems(false)
      dropdown:DockMargin(5, 5, 5, 5)
      dropdown:SetValue(gmInte.getTranslation("report_bug.importance_level.dsc", "How important is this bug?"))
      for key, value in ipairs(field.options) do
        dropdown:AddChoice(value.text, value.level)
      end

      gmInte.applyPaint(dropdown)
      table.insert(elements, dropdown)
    end
  end

  local buttonGrid = vgui.Create("DGrid", frame)
  buttonGrid:Dock(BOTTOM)
  buttonGrid:DockMargin(5, 10, 5, 5)
  buttonGrid:SetCols(2)
  buttonGrid:SetColWide(frame:GetWide() - 10)
  buttonGrid:SetRowHeight(35)
  local button = vgui.Create("DButton")
  button:SetText("Send Report")
  button:SetSize(buttonGrid:GetColWide() - 10, buttonGrid:GetRowHeight())
  gmInte.applyPaint(button)
  buttonGrid:AddItem(button)
  button.DoClick = function()
    local readyForSend = true
    if !elements[1]:GetText() || elements[1]:GetText() == "" then readyForSend = false end
    if !elements[2]:GetSelected() then readyForSend = false end
    if !elements[3]:GetText() || elements[3]:GetText() == "" then readyForSend = false end
    if !elements[4]:GetText() || elements[4]:GetText() == "" then readyForSend = false end
    if !elements[5]:GetText() || elements[5]:GetText() == "" then readyForSend = false end
    if !readyForSend then
      notification.AddLegacy(gmInte.getTranslation("report_bug.error.missing_fields", "All fields are required"), NOTIFY_ERROR, 5)
      return
    end

    local screenData = {}
    if screenCapture then
      local base64Capture = util.Base64Encode(screenCapture)
      local size = math.Round(string.len(base64Capture) / 1024)
      screenData = {
        ["screenshot"] = base64Capture,
        ["captureData"] = captureData,
        ["size"] = size .. "KB"
      }
    end

    local _, importanceValue = elements[2]:GetSelected()
    gmInte.http.post("/clients/:steamID64/servers/:serverID/bugs", {
      ["player"] = gmInte.getPlayerFormat(LocalPlayer()),
      ["screenshot"] = screenData,
      ["description"] = elements[1]:GetText(),
      ["importance"] = importanceValue,
      ["steps"] = elements[3]:GetText(),
      ["expected"] = elements[4]:GetText(),
      ["actual"] = elements[5]:GetText(),
    }, function()
      notification.AddLegacy(gmInte.getTranslation("report_bug.success", "Bug report sent successfully"), NOTIFY_GENERIC, 5)
      frame:Close()
    end, function() notification.AddLegacy(gmInte.getTranslation("report_bug.error.failed", "Failed to send bug report retry later"), NOTIFY_ERROR, 5) end)
  end
end

function gmInte.openReportBug()
  if ScreenshotRequested then return end
  local timerName = "gmInte:BugReport:Screenshot:Open"
  ScreenshotRequested = true
  gmInte.showScreenshotInfo = true
  screenCapture = nil
  screenFileID = gmInte.config.id .. "-" .. util.CRC(LocalPlayer():SteamID64() .. "-" .. tostring(os.time())) .. "-" .. tostring(os.time())
  timer.Create(timerName, 0.2, 0, function()
    if contextMenuOpen then return end
    timer.Remove(timerName)
    timer.Simple(0.5, openReportBug)
  end)
end

concommand.Add("gmi_report_bug", gmInte.openReportBug)
concommand.Add("gmod_integration_report_bug", gmInte.openReportBug)