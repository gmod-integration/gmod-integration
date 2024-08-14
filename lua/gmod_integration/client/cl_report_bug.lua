local Fields = {
  {
    ["title"] = Localize("#gmod_integration.report_bug.title", "Report a bug"),
    ["type"] = "image",
  },
  {
    ["title"] = Localize("#gmod_integration.report_bug.description", "Report a bug to the developers of this game."),
    ["type"] = "text",
    ["dsc"] = Localize("#gmod_integration.report_bug.description.dsc", "Please provide as much information as possible to help us fix the issue."),
    ["tall"] = 80,
  },
  {
    ["title"] = Localize("#gmod_integration.report_bug.importance_level", "Importance Level"),
    ["type"] = "dropdown",
    ["options"] = {Localize("#gmod_integration.report_bug.importance_level.critical", "Critical - Crash or made the game unplayable."), Localize("#gmod_integration.report_bug.importance_level.high", "High - Critical functionality is unusable."), Localize("#gmod_integration.report_bug.importance_level.medium", "Medium - Important functionality is unusable."), Localize("#gmod_integration.report_bug.importance_level.low", "Low - Cosmetic issue."), Localize("#gmod_integration.report_bug.importance_level.trivial", "Trivial - Very minor issue."),},
  },
  {
    ["title"] = Localize("#gmod_integration.report_bug.steps_to_reproduce", "Steps to Reproduce"),
    ["type"] = "text",
    ["dsc"] = Localize("#gmod_integration.report_bug.steps_to_reproduce.dsc", "Please provide a step-by-step guide on how to reproduce the bug."),
    ["tall"] = 80,
  },
  {
    ["title"] = Localize("#gmod_integration.report_bug.expected_result", "Expected result"),
    ["type"] = "text",
    ["dsc"] = Localize("#gmod_integration.report_bug.expected_result.dsc", "What did you expect to happen?"),
    ["tall"] = 50,
  },
  {
    ["title"] = Localize("#gmod_integration.report_bug.actual_result", "Actual result"),
    ["type"] = "text",
    ["dsc"] = Localize("#gmod_integration.report_bug.actual_result.dsc", "What actually happened?"),
    ["tall"] = 50,
  },
}

function gmInte.openReportBug()
  local captureData = {
    format = "jpeg",
    x = 0,
    y = 0,
    w = ScrW(),
    h = ScrH(),
    quality = 95,
  }

  local screenCapture = render.Capture(captureData)
  if screenCapture then file.Write("gmod_integration/report_bug_screenshot.jpeg", screenCapture) end
  local frame = vgui.Create("DFrame")
  frame:SetSize(500, (700 / 1080) * ScrH())
  frame:Center()
  frame:SetTitle(gmInte.getFrameName(Localize("#gmod_integration.report_bug.title", "Report Bug")))
  frame:MakePopup()
  gmInte.applyPaint(frame)
  // bug report = screenshot, description, steps to reproduce, expected result, actual result
  local dPanel = vgui.Create("DScrollPanel", frame)
  dPanel:Dock(FILL)
  gmInte.applyPaint(dPanel)
  local elements = {}
  for _ = 1, #Fields do
    local field = Fields[_]
    if field.type == "image" && !screenCapture then continue end
    local label = vgui.Create("DLabel", dPanel)
    label:Dock(TOP)
    label:DockMargin(5, 5, 5, 5)
    label:SetText(field.title)
    if field.type == "image" then
      local image = vgui.Create("DImage", dPanel)
      image:Dock(TOP)
      image:DockMargin(5, 5, 5, 5)
      image:SetImage("data/gmod_integration/report_bug_screenshot.jpeg")
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
      dropdown:DockMargin(5, 5, 5, 5)
      dropdown:SetValue(Localize("#gmod_integration.report_bug.importance_level.dsc", "How important is this bug?"))
      for i = 1, #field.options do
        dropdown:AddChoice(field.options[i])
      end

      dropdown:SetSortItems(false)
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
    for _, element in ipairs(elements) do
      if element:GetText() == "" then
        notification.AddLegacy(Localize("#gmod_integration.report_bug.error.missing_fields", "All fields are required"), NOTIFY_ERROR, 5)
        return
      end
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

    gmInte.http.post("/clients/:steamID64/servers/:serverID/bugs", {
      ["player"] = gmInte.getPlayerFormat(LocalPlayer()),
      ["screenshot"] = screenData,
      ["description"] = elements[1]:GetText(),
      ["importance"] = elements[2]:GetValue(),
      ["steps"] = elements[3]:GetText(),
      ["expected"] = elements[4]:GetText(),
      ["actual"] = elements[5]:GetText(),
    }, function()
      notification.AddLegacy(Localize("#gmod_integration.report_bug.success", "Bug report sent successfully"), NOTIFY_GENERIC, 5)
      frame:Close()
    end, function() notification.AddLegacy(Localize("#gmod_integration.report_bug.error.failed", "Failed to send bug report retry later"), NOTIFY_ERROR, 5) end)
  end
end

concommand.Add("gmi_report_bug", gmInte.openReportBug)
concommand.Add("gmod_integration_report_bug", gmInte.openReportBug)