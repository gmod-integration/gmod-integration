local function saveConfig(setting, value)
    gmInte.SendNet("3", {
        [setting] = value
    })
end

local configCat = {
    "Authentication",
    "Main",
    "Trust & Safety",
    "Punishment",
    "Other"
}

local possibleConfig = {
    ["id"] = {
        ["label"] = "ID",
        ["description"] = "Your server ID. You can find it on the webpanel.",
        ["type"] = "textEntry",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value)
        end,
        ["onEditDelay"] = 0.5,
        ["category"] = "Authentication"
    },
    ["token"] = {
        ["label"] = "Token",
        ["description"] = "Your server Token. You can find it on the webpanel.",
        ["type"] = "textEntry",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value)
        end,
        ["onEditDelay"] = 0.5,
        ["category"] = "Authentication"
    },
    ["logs"] = {
        ["label"] = "Logs",
        ["description"] = "Activate or deactivate the logs.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Main"
    },
    ["filterOnBan"] = {
        ["label"] = "Block Discord Ban Player",
        ["description"] = "Block players that are banned on the discord server.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Trust & Safety"
    },
    ["filterOnTrust"] = {
        ["label"] = "Block UnTrust Player",
        ["description"] = "",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Trust & Safety"
    },
    ["minimalTrust"] = {
        ["label"] = "Minimal Trust Level",
        ["description"] = "Your server ID. You can find it on the webpanel.",
        ["type"] = "textEntry",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value)
        end,
        ["onEditDelay"] = 0.5,
        ["category"] = "Trust & Safety"
    },
    ["syncChat"] = {
        ["label"] = "Sync Chat",
        ["description"] = "Sync the chat between the server and the discord server.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Main"
    },
    ["syncBan"] = {
        ["label"] = "Sync Ban",
        ["description"] = "Sync the chat between the server and the discord server.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Punishment"
    },
    ["syncTimeout"] = {
        ["label"] = "Sync Timeout",
        ["description"] = "Sync the chat between the server and the discord server.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Punishment"
    },
    ["syncKick"] = {
        ["label"] = "Sync Kick",
        ["description"] = "Sync the chat between the server and the discord server.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Punishment"
    },
    ["forcePlayerLink"] = {
        ["label"] = "Force Player Verif",
        ["description"] = "Sync the chat between the server and the discord server.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Main"
    },
    ["supportLink"] = {
        ["label"] = "Support Link",
        ["description"] = "Your server ID. You can find it on the webpanel.",
        ["type"] = "textEntry",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value)
        end,
        ["onEditDelay"] = 0.5,
        ["category"] = "Trust & Safety"
    },
    ["debug"] = {
        ["label"] = "Debug",
        ["description"] = "Activate or deactivate the debug mode.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Other"
    },
}

local buttonsInfo = {
    {
        ["label"] = "Open Webpanel",
        ["func"] = function()
            gui.OpenURL("https://gmod-integration.com/config/server")
        end,
    },
    {
        ["label"] = "Test Connection",
        ["func"] = function()
            gmInte.SendNet("1")
        end,
    },
}

function gmInte.openConfigMenu(data)
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 400)
    frame:Center()
    frame:SetTitle("Gmod Integration - Server Config")
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()

    local scrollPanel = vgui.Create("DScrollPanel", frame)
    scrollPanel:Dock(FILL)

    // add message explain that this config is superiort then the webpanel config
    local messagePanel = vgui.Create("DPanel", scrollPanel)
    messagePanel:Dock(TOP)
    messagePanel:SetSize(300, 60)
    messagePanel:DockMargin(10, 0, 10, 10)
    messagePanel:SetBackgroundColor(Color(0, 0, 0, 0))

    local messageLabel = vgui.Create("DLabel", messagePanel)
    messageLabel:Dock(FILL)
    messageLabel:SetText("This config is superior to the webpanel config. If you change something here you can override the webpanel config. For example if you disable the logs here, the logs will not be available on the webpanel.")
    messageLabel:SetWrap(true)


    for k, catName in pairs(configCat) do
        // create DCollapsibleCategory
        local collapsibleCategory = vgui.Create("DCollapsibleCategory", scrollPanel)
        collapsibleCategory:Dock(TOP)
        collapsibleCategory:DockMargin(10, 0, 10, 10)
        collapsibleCategory:SetLabel(catName)
        collapsibleCategory:SetExpanded(true)

        // create DPanelList as content of DCollapsibleCategory
        local configList = vgui.Create("DPanelList", collapsibleCategory)
        configList:Dock(FILL)
        configList:SetSpacing(5)
        configList:EnableHorizontal(false)
        configList:EnableVerticalScrollbar(false)
        collapsibleCategory:SetContents(configList)

        for k, v in pairs(possibleConfig) do
            if v.category == catName then
                local panel = vgui.Create("DPanel", configList)
                panel:Dock(TOP)
                panel:SetSize(300, 25)
                panel:SetBackgroundColor(Color(0, 0, 0, 0))

                local label = vgui.Create("DLabel", panel)
                label:Dock(LEFT)
                label:SetSize(140, 25)
                label:SetText(v.label)
                -- label:SetContentAlignment(5)

                local input

                if v.type == "textEntry" then
                    input = vgui.Create("DTextEntry", panel)
                    input:SetText(v.value(k, data[k]))
                    local isLastID = 0
                    input.OnChange = function(self)
                        isLastID = isLastID + 1
                        local isLocalLastID = isLastID
                        timer.Simple(v.onEditDelay || 0.5, function()
                            if isLocalLastID == isLastID then
                                v.onEdit(k, self:GetValue())
                            end
                        end)
                    end
                elseif v.type == "checkbox" then
                    input = vgui.Create("DComboBox", panel)
                    input:AddChoice("Enabled")
                    input:AddChoice("Disabled")
                    input:SetText(v.value(k, data[k]) && "Enabled" || "Disabled")
                    input.OnSelect = function(self, index, value)
                        v.onEdit(k, value)
                    end
                end

                input:Dock(FILL)
                input:SetSize(150, 25)

                if v.description then
                    input:SetTooltip(v.description)
                end

                configList:AddItem(panel)
            end
        end
    end

    // grid of buttons (2 buttons per row take 50% of the width)
    local buttonGrid = vgui.Create("DGrid", frame)
    buttonGrid:Dock(BOTTOM)
    buttonGrid:DockMargin(5, 10, 5, 5)
    buttonGrid:SetCols(2)
    buttonGrid:SetColWide(frame:GetWide() / 2 - 10)
    buttonGrid:SetRowHeight(35)

    for k, v in pairs(buttonsInfo) do
        local button = vgui.Create("DButton")
        button:SetText(v.label)
        button.DoClick = function()
            v.func()
        end
        button:SetSize(buttonGrid:GetColWide(), buttonGrid:GetRowHeight())
        buttonGrid:AddItem(button)
    end
end

list.Set("DesktopWindows", "GmodIntegration:DesktopWindows", {
    // use icon 'gear'
    icon = "icon16/wrench.png",
    title = "Gmod Integration",
    width = 32,
    height = 32,
    onewindow = true,
    init = function(icon, window)
        window:Close()
        gmInte.openAdminConfig()
    end
    }
)