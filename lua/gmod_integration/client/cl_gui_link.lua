function gmInte.openVerifPopup()
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 140)
    frame:Center()
    frame:SetTitle("Gmod Integration - Verification Required")
    frame:SetDraggable(false)
    frame:ShowCloseButton(false)
    frame:MakePopup()

    local messagePanel = vgui.Create("DPanel", frame)
    messagePanel:Dock(TOP)
    messagePanel:SetSize(300, 40)
    messagePanel:DockMargin(10, 0, 10, 10)
    messagePanel:SetBackgroundColor(Color(0, 0, 0, 0))

    local messageLabel = vgui.Create("DLabel", messagePanel)
    messageLabel:Dock(FILL)
    messageLabel:SetText("Hey! It looks like you haven't linked your Steam account to Discord yet. This is required to play on this server. Please click the button below to link your account. After you've done that, click the refresh button.")
    messageLabel:SetContentAlignment(5)
    messageLabel:SetWrap(true)

    local buttonGrid = vgui.Create("DGrid", frame)
    buttonGrid:Dock(BOTTOM)
    buttonGrid:DockMargin(5, 10, 5, 5)
    buttonGrid:SetCols(2)
    buttonGrid:SetColWide(frame:GetWide() / 2 - 10)
    buttonGrid:SetRowHeight(35)

    local button = vgui.Create("DButton")
    button:SetText("Open Verification Page")
    button.DoClick = function()
        gui.OpenURL("https://verif.gmod-integration.com")
    end
    button:SetSize(buttonGrid:GetColWide(), buttonGrid:GetRowHeight())
    buttonGrid:AddItem(button)

    local button = vgui.Create("DButton")
    button:SetText("Refresh Verification")
    button.DoClick = function()
        gmInte.http.get("/players/" .. LocalPlayer():SteamID64(), function(code, body)
            gmInte.SendNet(6)
            frame:Close()
        end,
        function(err)
            LocalPlayer():ChatPrint("Failed to refresh verification: " .. err)
        end)
    end
    button:SetSize(buttonGrid:GetColWide(), buttonGrid:GetRowHeight())
    buttonGrid:AddItem(button)
end

gmInte.openVerifPopup()