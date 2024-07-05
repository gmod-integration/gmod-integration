function gmInte.openVerifPopup()
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 200)
    frame:Center()
    frame:SetTitle("Gmod Integration - Verification Required")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()
    gmInte.applyPaint(frame)
    local messageLabel = vgui.Create("DLabel", frame)
    messageLabel:Dock(FILL)
    messageLabel:DockMargin(10, 0, 10, 0)
    messageLabel:SetText("Hey,\nIt looks like you haven't linked your Steam account to Discord yet. This is required to play on this server. Please click the button below to link your account.\n\nAfter you've done that, click the refresh button.")
    messageLabel:SetContentAlignment(5)
    messageLabel:SetFont("GmodIntegration_Roboto_16")
    messageLabel:SetWrap(true)
    local buttonGrid = vgui.Create("DGrid", frame)
    buttonGrid:Dock(BOTTOM)
    buttonGrid:DockMargin(10, 0, 10, 10)
    buttonGrid:SetCols(2)
    buttonGrid:SetColWide(frame:GetWide() / 2 - 10)
    buttonGrid:SetRowHeight(35)
    local button = vgui.Create("DButton")
    button:SetText("Open Verification Page")
    button.DoClick = function() gui.OpenURL("https://gmod-integration.com/account") end
    button:SetSize(buttonGrid:GetColWide() - 10, buttonGrid:GetRowHeight())
    gmInte.applyPaint(button)
    buttonGrid:AddItem(button)
    local button = vgui.Create("DButton")
    button:SetText("Refresh Verification")
    button.DoClick = function()
        gmInte.http.get("/users?steamID64" .. LocalPlayer():SteamID64(), function(code, body)
            gmInte.SendNet("verifyMe")
            frame:Close()
        end, function(code, body) LocalPlayer():ChatPrint("Failed to refresh verification: " .. code) end)
    end

    button:SetSize(buttonGrid:GetColWide() - 10, buttonGrid:GetRowHeight())
    gmInte.applyPaint(button)
    buttonGrid:AddItem(button)
end