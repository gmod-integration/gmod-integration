local function saveConfig(setting, value)
    gmInte.SendNet("saveConfig", {
        [setting] = value
    })
end

local configCat = {
    "Authentication",
    "Main",
    "Trust & Safety",
    -- "Punishment",
    "Advanced",
}

local possibleConfig = {
    {
        ["id"] = "id",
        ["label"] = "Server ID",
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
    {
        ["id"]= "token",
        ["label"] = "Server Token",
        ["description"] = "Server Token found on the webpanel.",
        ["type"] = "textEntry",
        ["secret"] = true,
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value)
        end,
        ["onEditDelay"] = 0.5,
        ["category"] = "Authentication"
    },
    -- {
    --     ["id"]= "sendLog",
    --     ["label"] = "Logs",
    --     ["description"] = "Activate or deactivate logs.",
    --     ["type"] = "checkbox",
    --     ["value"] = function(setting, value)
    --         return value
    --     end,
    --     ["onEdit"] = function(setting, value)
    --         saveConfig(setting, value == "Enabled" && true || false)
    --     end,
    --     ["category"] = "Main"
    -- },
    -- {
    --     ["id"]= "logBotActions",
    --     ["label"] = "Log Bot Actions",
    --     ["description"] = "Activate or deactivate logs for bot actions.",
    --     ["type"] = "checkbox",
    --     ["value"] = function(setting, value)
    --         return value
    --     end,
    --     ["onEdit"] = function(setting, value)
    --         saveConfig(setting, value == "Enabled" && true || false)
    --     end,
    --     ["category"] = "Main"
    -- },
    {
        ["id"]= "maintenance",
        ["label"] = "Maintenance",
        ["description"] = "Activate or deactivate maintenance mode.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Main"
    },
    {
        ["id"]= "filterOnBan",
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
    -- {
    --     ["id"]= "filterOnTrust",
    --     ["label"] = "Block UnTrust Player",
    --     ["description"] = "Block players with a trust level lower than the minimal trust level set in the config.",
    --     ["type"] = "checkbox",
    --     ["value"] = function(setting, value)
    --         return value
    --     end,
    --     ["onEdit"] = function(setting, value)
    --         saveConfig(setting, value == "Enabled" && true || false)
    --     end,
    --     ["category"] = "Trust & Safety"
    -- },
    -- {
    --     ["id"]= "minimalTrust",
    --     ["label"] = "Minimal Trust Level",
    --     ["description"] = "The minimal trust level to be able to join the server.",
    --     ["type"] = "textEntry",
    --     ["value"] = function(setting, value)
    --         return value
    --     end,
    --     ["onEdit"] = function(setting, value)
    --         saveConfig(setting, value)
    --     end,
    --     ["onEditDelay"] = 0.5,
    --     ["category"] = "Trust & Safety"
    -- },
    -- {
    --     ["id"]= "syncChat",
    --     ["label"] = "Sync Chat",
    --     ["description"] = "Sync chat between the server and the discord server.",
    --     ["websocket"] = true,
    --     ["restart"] = true,
    --     ["type"] = "checkbox",
    --     ["value"] = function(setting, value)
    --         return value
    --     end,
    --     ["onEdit"] = function(setting, value)
    --         saveConfig(setting, value == "Enabled" && true || false)
    --     end,
    --     ["category"] = "Main"
    -- },
    -- {
    --     ["id"]= "syncBan",
    --     ["label"] = "Sync Ban",
    --     ["description"] = "Sync chat between the server and the discord server.",
    --     ["type"] = "checkbox",
    --     ["condition"] = function(data)
    --         return false // Disabled for now
    --     end,
    --     ["value"] = function(setting, value)
    --         return value
    --     end,
    --     ["onEdit"] = function(setting, value)
    --         saveConfig(setting, value == "Enabled" && true || false)
    --     end,
    --     ["category"] = "Punishment"
    -- },
    -- {
    --     ["id"]= "syncTimeout",
    --     ["label"] = "Sync Timeout",
    --     ["description"] = "Sync chat between the server and the discord server.",
    --     ["type"] = "checkbox",
    --     ["condition"] = function(data)
    --         return false // Disabled for now
    --     end,
    --     ["value"] = function(setting, value)
    --         return value
    --     end,
    --     ["onEdit"] = function(setting, value)
    --         saveConfig(setting, value == "Enabled" && true || false)
    --     end,
    --     ["category"] = "Punishment"
    -- },
    -- {
    --     ["id"]= "syncKick",
    --     ["label"] = "Sync Kick",
    --     ["description"] = "Sync chat between the server and the discord server.",
    --     ["type"] = "checkbox",
    --     ["condition"] = function(data)
    --         return false // Disabled for now
    --     end,
    --     ["value"] = function(setting, value)
    --         return value
    --     end,
    --     ["onEdit"] = function(setting, value)
    --         saveConfig(setting, value == "Enabled" && true || false)
    --     end,
    --     ["category"] = "Punishment"
    -- },
    {
        ["id"]= "forcePlayerLink",
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
    {
        ["id"]= "supportLink",
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
    {
        ["id"]= "debug",
        ["label"] = "Debug",
        ["description"] = "Activate or deactivate debug mode.",
        ["type"] = "checkbox",
        ["value"] = function(setting, value)
            return value
        end,
        ["position"] = 1,
        ["onEdit"] = function(setting, value)
            saveConfig(setting, value == "Enabled" && true || false)
        end,
        ["category"] = "Advanced"
    },
    {
        ["id"]= "websocketFQDN",
        ["label"] = "Websocket FQDN",
        ["description"] = "Websocket FQDN that will be used for the Websocket connection.",
        ["type"] = "textEntry",
        ["value"] = function(setting, value)
            return value
        end,
        ["resetIfEmpty"] = true,
        ["defaultValue"] = "ws.gmod-integration.com",
        ["onEdit"] = function(setting, value)
            if (!value || value == "") then return end
            saveConfig(setting, value)
        end,
        ["onEditDelay"] = 0.5,
        ["category"] = "Advanced"
    },
    {
        ["id"]= "apiFQDN",
        ["label"] = "API FQDN",
        ["description"] = "API FQDN that will be used for the API connection.",
        ["type"] = "textEntry",
        ["resetIfEmpty"] = true,
        ["defaultValue"] = "ws.gmod-integration.com",
        ["value"] = function(setting, value)
            return value
        end,
        ["onEdit"] = function(setting, value)
            if (!value || value == "") then return end
            saveConfig(setting, value)
        end,
        ["onEditDelay"] = 0.5,
        ["category"] = "Advanced"
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
    frame:SetTitle(gmInte.getFrameName("Restart Required"))
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()
    gmInte.applyPaint(frame)

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
    buttonGrid:SetColWide(frame:GetWide() / 2 - 5)
    buttonGrid:SetRowHeight(35)

    local button = vgui.Create("DButton")
    button:SetText("Restart")
    button.DoClick = function()
        frame:Close()
        gmInte.SendNet("restartMap")
    end
    button:SetSize(buttonGrid:GetColWide() -10, buttonGrid:GetRowHeight())
    gmInte.applyPaint(button)
    buttonGrid:AddItem(button)

    local button = vgui.Create("DButton")
    button:SetText("Maybe Later")
    button.DoClick = function()
        frame:Close()
    end
    button:SetSize(buttonGrid:GetColWide() -10, buttonGrid:GetRowHeight())
    gmInte.applyPaint(button)
    buttonGrid:AddItem(button)
end

function gmInte.openConfigMenu(data)
    local needRestart = false

    if (gmInte.openAdminPanel) then return end
    gmInte.openAdminPanel = true

    local frame = vgui.Create("DFrame")
    frame:SetSize(400, (600 / 1080) * ScrH())
    frame:Center()
    frame:SetTitle(gmInte.getFrameName("Server Config"))
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()
    gmInte.applyPaint(frame)

    local scrollPanel = vgui.Create("DScrollPanel", frame)
    scrollPanel:Dock(FILL)

    local messagePanel = vgui.Create("DPanel", scrollPanel)
    messagePanel:Dock(TOP)
    messagePanel:SetSize(300, 60)
    messagePanel:DockMargin(10, 0, 10, 10)
    messagePanel:SetBackgroundColor(Color(0, 0, 0, 0))

    local messageLabel = vgui.Create("DLabel", messagePanel)
    messageLabel:Dock(FILL)
    messageLabel:SetText("Here you can configure your server settings.\nServer ID and Token are available on the webpanel in the server settings.\nThe documentation is available at https://docs.gmod-integration.com/\nIf you need help, please contact us on our discord server.")
    messageLabel:SetWrap(true)

    for k, catName in pairs(configCat) do
        local collapsibleCategory = vgui.Create("DCollapsibleCategory", scrollPanel)
        collapsibleCategory:Dock(TOP)
        collapsibleCategory:DockMargin(10, 0, 10, 10)
        collapsibleCategory:SetLabel(catName)
        collapsibleCategory:SetExpanded(true)
        gmInte.applyPaint(collapsibleCategory)

        local configList = vgui.Create("DPanelList", collapsibleCategory)
        configList:Dock(FILL)
        configList:SetSpacing(5)
        configList:EnableHorizontal(false)
        configList:EnableVerticalScrollbar(false)
        collapsibleCategory:SetContents(configList)

        local categoryConfig = {}
        for k, v in pairs(possibleConfig) do
            if v.category == catName then
                table.insert(categoryConfig, v)
            end
        end

        // Sort by position
        table.sort(categoryConfig, function(a, b)
            return (a.position || 0) < (b.position || 0)
        end)

        for k, actualConfig in pairs(categoryConfig) do
            local panel = vgui.Create("DPanel", configList)
            panel:Dock(TOP)
            panel:SetSize(300, 25)
            panel:SetBackgroundColor(Color(0, 0, 0, 0))

            local label = vgui.Create("DLabel", panel)
            label:Dock(LEFT)
            label:SetSize(140, 25)
            label:SetText(actualConfig.label)
            label:SetContentAlignment(4)

            local input

            if actualConfig.type == "textEntry" then
                input = vgui.Create("DTextEntry", panel)
                local value = actualConfig.value(actualConfig.id, data[actualConfig.id] || "")
                if (actualConfig.secret) then
                    input:SetText("*** Click to show ***")
                else
                    input:SetText(value)
                end
                input.OnGetFocus = function(self)
                    if (actualConfig.secret) then
                        self:SetText(value)
                    end
                end
                input.OnLoseFocus = function(self)
                    if (actualConfig.secret) then
                        self:SetText("*** Click to show ***")
                    end
                end
                local isLastID = 0
                local initialValue = value
                input.OnChange = function(self)
                    if (self:GetValue() == initialValue) then return end
                    if (actualConfig.resetIfEmpty && self:GetValue() == "" && actualConfig.defaultValue) then
                        self:SetText(actualConfig.defaultValue)
                        return
                    end
                    isLastID = isLastID + 1
                    local isLocalLastID = isLastID
                    timer.Simple(actualConfig.onEditDelay || 0.5, function()
                        if isLocalLastID == isLastID then
                            actualConfig.onEdit(actualConfig.id, self:GetValue())
                        end
                    end)
                end
            elseif (actualConfig.type == "checkbox") then
                input = vgui.Create("DComboBox", panel)
                if (actualConfig.condition && !actualConfig.condition(data)) then
                    input:SetEnabled(false)
                end
                input:AddChoice("Enabled")
                input:AddChoice("Disabled")
                input:SetText(actualConfig.value(actualConfig.id, data[actualConfig.id]) && "Enabled" || "Disabled")
                input.OnSelect = function(self, index, value)
                    if (actualConfig.restart) then
                        needRestart = true
                    end
                    actualConfig.onEdit(actualConfig.id, value)
                end
            end

            input:Dock(FILL)
            input:SetSize(150, 25)

            if (actualConfig.description) then
                if (actualConfig.websocket && !data.websocket) then
                    actualConfig.description = actualConfig.description .. "\n\nThis feature require a websocket connection to work properly."
                end
                if (actualConfig.disable) then
                    actualConfig.description = actualConfig.description .. "\n\nThis feature will be available soon."
                end
                input:SetTooltip(actualConfig.description)
            end

            configList:AddItem(panel)
        end
    end

    local buttonGrid = vgui.Create("DGrid", frame)
    buttonGrid:Dock(BOTTOM)
    buttonGrid:DockMargin(5, 10, 5, -5)
    buttonGrid:SetCols(2)
    buttonGrid:SetColWide(frame:GetWide() / 2 - 5)
    buttonGrid:SetRowHeight(45)

    local buttonsCount = 0
    for k, v in pairs(buttonsInfo) do
        if (v.condition && !v.condition(data)) then continue end
        local button = vgui.Create("DButton")
        button:SetText(v.label)
        button.DoClick = function()
            v.func(data)
        end
        gmInte.applyPaint(button)
        button:SetSize(buttonGrid:GetColWide() - 10, buttonGrid:GetRowHeight() - 10)
        buttonGrid:AddItem(button)
        buttonsCount = buttonsCount + 1
    end

    if (buttonsCount % 2 == 1) then
        local lastButton = buttonGrid:GetItems()[buttonsCount]
        lastButton:SetWide(frame:GetWide() - 20)
    end

    frame.OnClose = function()
        gmInte.openAdminPanel = false
        if (needRestart) then gmInte.needRestart() end
    end
end

//
// Concommands
//

concommand.Add("gmod_integration_admin", function() gmInte.SendNet("getConfig") end)
concommand.Add("gmi_admin", function() gmInte.SendNet("getConfig") end)