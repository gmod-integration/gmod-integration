local function saveConfig(setting, value)
    gmInte.SendNet("saveConfig", {
        [setting] = value
    })
end

local configCat = {
    "Authentication",
    "Main",
    "Trust & Safety",
    "Punishment",
    "Advanced",
}

local possibleConfig = {
    ["id"] = {
        ["label"] = "ID",
        ["description"] = "Server ID found on the webpanel.",
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
        ["description"] = "Server Token found on the webpanel.",
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
    ["sendLog"] = {
        ["label"] = "Logs",
        ["description"] = "Activate or deactivate logs.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Main"
    },
    ["logBotActions"] = {
        ["label"] = "Log Bot Actions",
        ["description"] = "Activate or deactivate logs for bot actions.",
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
        ["description"] = "Block players banned on the discord server.",
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
        ["description"] = "Block players with a trust level lower than the minimal trust level set in the config.",
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
        ["description"] = "The minimal trust level to be able to join the server.",
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
        ["description"] = "Sync chat between the server and the discord server.",
        ["websocket"] = true,
        ["restart"] = true,
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
        ["description"] = "Sync chat between the server and the discord server.",
        ["type"] = "checkbox",
        ["condition"] = function(data)
            return false // Disabled for now
        end,
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
        ["description"] = "Sync chat between the server and the discord server.",
        ["type"] = "checkbox",
        ["condition"] = function(data)
            return false // Disabled for now
        end,
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
        ["description"] = "Sync chat between the server and the discord server.",
        ["type"] = "checkbox",
        ["condition"] = function(data)
            return false // Disabled for now
        end,
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
        ["description"] = "Sync chat between the server and the discord server.",
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
        ["description"] = "Server ID found on the webpanel.",
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
        ["description"] = "Activate or deactivate debug mode.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Advanced"
    },
    ['devInstance'] = {
        ["label"] = "Dev Instance",
        ["description"] = "Activate or deactivate the dev instance of the API and Websocket.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["condition"] = function(data)
            return data.debug
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Advanced"
    }
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
            gmInte.SendNet("testConnection")
        end,
    },
    {
        ["label"] = "Buy Premium",
        ["func"] = function()
            gui.OpenURL("https://gmod-integration.com/premium")
        end,
    },
    {
        ["label"] = "Install Websocket",
        ["condition"] = function(data)
            return !data.websocket
        end,
        ["func"] = function()
            gui.OpenURL("https://github.com/FredyH/GWSockets/releases")
        end,
    },
    {
        ["label"] = "Load Server Config",
        ["condition"] = function(data)
            return data.debug
        end,
        ["func"] = function(data)
            gmInte.config = data
        end,
    }
}

local colorTable = {
    ["text"] = Color(255, 255, 255, 255),
    ["background"] = Color(0, 0, 0, 200),
    ["button"] = Color(0, 0, 0, 200),
    ["buttonHover"] = Color(0, 0, 0, 255),
    ["buttonText"] = Color(255, 255, 255, 255),
    ["buttonTextHover"] = Color(255, 255, 255, 255),
}

function gmInte.needRestart()
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 120)
    frame:Center()
    frame:SetTitle("Gmod Integration - Restart Required")
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()

    local messagePanel = vgui.Create("DPanel", frame)
    messagePanel:Dock(TOP)
    messagePanel:SetSize(300, 40)
    messagePanel:DockMargin(10, 0, 10, 10)
    messagePanel:SetBackgroundColor(Color(0, 0, 0, 0))

    local messageLabel = vgui.Create("DLabel", messagePanel)
    messageLabel:Dock(FILL)
    messageLabel:SetText("Some changes require a restart to be applied.\nRestart now ?")
    messageLabel:SetContentAlignment(5)
    messageLabel:SetWrap(true)

    local buttonGrid = vgui.Create("DGrid", frame)
    buttonGrid:Dock(BOTTOM)
    buttonGrid:DockMargin(5, 10, 5, 5)
    buttonGrid:SetCols(2)
    buttonGrid:SetColWide(frame:GetWide() / 2 - 10)
    buttonGrid:SetRowHeight(35)

    local button = vgui.Create("DButton")
    button:SetText("Restart")
    button.DoClick = function()
        frame:Close()
        gmInte.SendNet("restartMap")
    end
    button:SetSize(buttonGrid:GetColWide(), buttonGrid:GetRowHeight())
    buttonGrid:AddItem(button)

    local button = vgui.Create("DButton")
    button:SetText("Maybe Later")
    button.DoClick = function()
        frame:Close()
    end
    button:SetSize(buttonGrid:GetColWide(), buttonGrid:GetRowHeight())
    buttonGrid:AddItem(button)
end

function gmInte.openConfigMenu(data)
    local needRestart = false

    local frame = vgui.Create("DFrame")
    frame:SetSize(400, (600 / 1080) * ScrH())
    frame:Center()
    frame:SetTitle("Gmod Integration - Server Config")
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()

    local scrollPanel = vgui.Create("DScrollPanel", frame)
    scrollPanel:Dock(FILL)

    local messagePanel = vgui.Create("DPanel", scrollPanel)
    messagePanel:Dock(TOP)
    messagePanel:SetSize(300, 60)
    messagePanel:DockMargin(10, 0, 10, 10)
    messagePanel:SetBackgroundColor(Color(0, 0, 0, 0))

    local messageLabel = vgui.Create("DLabel", messagePanel)
    messageLabel:Dock(FILL)
    messageLabel:SetText("This config is superior to the webpanel config.\nIf you change something here you can override the webpanel config.\nSome features require a websocket connection to work properly.")
    messageLabel:SetWrap(true)

    for k, catName in pairs(configCat) do
        local collapsibleCategory = vgui.Create("DCollapsibleCategory", scrollPanel)
        collapsibleCategory:Dock(TOP)
        collapsibleCategory:DockMargin(10, 0, 10, 10)
        collapsibleCategory:SetLabel(catName)
        collapsibleCategory:SetExpanded(true)

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
                label:SetContentAlignment(4)

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
                elseif (v.type == "checkbox") then
                    input = vgui.Create("DComboBox", panel)
                    if (v.condition && !v.condition(data)) then
                        input:SetEnabled(false)
                    end
                    input:AddChoice("Enabled")
                    input:AddChoice("Disabled")
                    input:SetText(v.value(k, data[k]) && "Enabled" || "Disabled")
                    input.OnSelect = function(self, index, value)
                        if (v.restart) then
                            needRestart = true
                        end
                        v.onEdit(k, value)
                    end
                end

                input:Dock(FILL)
                input:SetSize(150, 25)

                if (v.description) then
                    if (v.websocket && !data.websocket) then
                        v.description = v.description .. "\n\nThis feature require a websocket connection to work properly."
                    end
                    if (v.disable) then
                        v.description = v.description .. "\n\nThis feature will be available soon."
                    end
                    input:SetTooltip(v.description)
                end

                configList:AddItem(panel)
            end
        end
    end

    local buttonGrid = vgui.Create("DGrid", frame)
    buttonGrid:Dock(BOTTOM)
    buttonGrid:DockMargin(5, 10, 5, 5)
    buttonGrid:SetCols(2)
    buttonGrid:SetColWide(frame:GetWide() / 2 - 10)
    buttonGrid:SetRowHeight(35)

    local buttonsCount = 0
    for k, v in pairs(buttonsInfo) do
        if (v.condition && !v.condition(data)) then continue end
        local button = vgui.Create("DButton")
        button:SetText(v.label)
        button.DoClick = function()
            v.func(data)
        end
        button:SetSize(buttonGrid:GetColWide(), buttonGrid:GetRowHeight())
        buttonGrid:AddItem(button)
        buttonsCount = buttonsCount + 1
    end

    if (buttonsCount % 2 == 1) then
        local lastButton = buttonGrid:GetItems()[buttonsCount]
        lastButton:SetWide(frame:GetWide() - 20)
    end

    frame.OnClose = function()
        if (needRestart) then gmInte.needRestart() end
    end
end