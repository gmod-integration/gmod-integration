local function saveConfig(setting, value)
    gmInte.SendNet("saveConfig", {
        [setting] = value
    })
end

local colorTable = {
    ["text"] = Color(255, 255, 255, 255),
    ["background"] = Color(0, 0, 0, 200),
    ["button"] = Color(0, 0, 0, 200),
    ["buttonHover"] = Color(0, 0, 0, 255),
    ["buttonText"] = Color(255, 255, 255, 255),
    ["buttonTextHover"] = Color(255, 255, 255, 255),
}

// function to open a msg info say in game config has been disabled because default sv_config.lua has been edited
function gmInte.openDisabledConfig()
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 120)
    frame:Center()
    frame:SetTitle(gmInte.getFrameName(gmInte.getTranslation("admin.config_disabled", "Config Disabled")))
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
    messageLabel:SetText(gmInte.getTranslation("admin.config_disabled_description", "The config has been disabled because the default sv_config.lua has been edited.\nPlease restore the default sv_config.lua to enable the config again."))
    messageLabel:SetContentAlignment(5)
    messageLabel:SetWrap(true)
    local buttonGrid = vgui.Create("DGrid", frame)
    buttonGrid:Dock(BOTTOM)
    buttonGrid:DockMargin(5, 10, 5, 5)
    buttonGrid:SetCols(1)
    buttonGrid:SetColWide(frame:GetWide() - 10)
    buttonGrid:SetRowHeight(35)
    local button = vgui.Create("DButton")
    button:SetText(gmInte.getTranslation("admin.ok", "OK"))
    button.DoClick = function() frame:Close() end
    button:SetSize(buttonGrid:GetColWide() - 10, buttonGrid:GetRowHeight())
    gmInte.applyPaint(button)
    buttonGrid:AddItem(button)
    frame.OnClose = function() gmInte.openAdminPanel = false end
    frame.OnRemove = function() gmInte.openAdminPanel = false end
    frame.OnKeyCodePressed = function(self, key) if key == KEY_ESCAPE then self:Close() end end
end

function gmInte.needRestart()
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 120)
    frame:Center()
    frame:SetTitle(gmInte.getFrameName(gmInte.getTranslation("admin.restart_required", "Restart Required")))
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
    messageLabel:SetText(gmInte.getTranslation("admin.restart_required_description", "Some changes require a restart to be applied.\nRestart now ?"))
    messageLabel:SetContentAlignment(5)
    messageLabel:SetWrap(true)
    local buttonGrid = vgui.Create("DGrid", frame)
    buttonGrid:Dock(BOTTOM)
    buttonGrid:DockMargin(5, 10, 5, 5)
    buttonGrid:SetCols(2)
    buttonGrid:SetColWide(frame:GetWide() / 2 - 5)
    buttonGrid:SetRowHeight(35)
    local button = vgui.Create("DButton")
    button:SetText(gmInte.getTranslation("admin.restart", "Restart"))
    button.DoClick = function()
        frame:Close()
        gmInte.SendNet("restartMap")
    end

    button:SetSize(buttonGrid:GetColWide() - 10, buttonGrid:GetRowHeight())
    gmInte.applyPaint(button)
    buttonGrid:AddItem(button)
    local button = vgui.Create("DButton")
    button:SetText(gmInte.getTranslation("admin.maybe_later", "Maybe Later"))
    button.DoClick = function() frame:Close() end
    button:SetSize(buttonGrid:GetColWide() - 10, buttonGrid:GetRowHeight())
    gmInte.applyPaint(button)
    buttonGrid:AddItem(button)
end

function gmInte.openConfigMenu(data)
    local configCat = {gmInte.getTranslation("admin.authentication", "Authentication"), gmInte.getTranslation("admin.main", "Main"), gmInte.getTranslation("admin.trust_safety", "Trust & Safety"), gmInte.getTranslation("admin.advanced", "Advanced")}
    local possibleConfig = {
        {
            ["id"] = "id",
            ["label"] = gmInte.getTranslation("admin.server_id", "Server ID"),
            ["description"] = gmInte.getTranslation("admin.server_id_description", "Server ID found on the webpanel."),
            ["type"] = "textEntry",
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["onEditDelay"] = 0.5,
            ["category"] = gmInte.getTranslation("admin.authentication", "Authentication")
        },
        {
            ["id"] = "token",
            ["label"] = gmInte.getTranslation("admin.server_token", "Server Token"),
            ["description"] = gmInte.getTranslation("admin.server_token_description", "Server Token found on the webpanel."),
            ["type"] = "textEntry",
            ["secret"] = true,
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["onEditDelay"] = 0.5,
            ["category"] = gmInte.getTranslation("admin.authentication", "Authentication")
        },
        {
            ["id"] = "maintenance",
            ["label"] = gmInte.getTranslation("admin.maintenance", "Maintenance"),
            ["description"] = gmInte.getTranslation("admin.maintenance_description", "Activate or deactivate maintenance mode."),
            ["type"] = "checkbox",
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["category"] = gmInte.getTranslation("admin.main", "Main")
        },
        {
            ["id"] = "language",
            ["label"] = gmInte.getTranslation("admin.language", "Language"),
            ["description"] = gmInte.getTranslation("admin.language_description", "Language used in the interface."),
            ["type"] = "combo",
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["reloadOnEdit"] = true,
            ["category"] = gmInte.getTranslation("admin.main", "Main"),
            ["values"] = {
                ["de"] = "Deutsch",
                ["en"] = "English",
                ["es"] = "Español",
                ["fr"] = "Français",
                ["it"] = "Italiano",
                ["pl"] = "Polski",
                ["ru"] = "Русский",
                ["tr"] = "Türkçe",
            }
        },
        {
            ["id"] = "filterOnBan",
            ["label"] = gmInte.getTranslation("admin.filter_on_ban", "Block Discord Ban Player"),
            ["description"] = gmInte.getTranslation("admin.filter_on_ban_description", "Block players banned on the discord server."),
            ["type"] = "checkbox",
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["category"] = gmInte.getTranslation("admin.trust_safety", "Trust & Safety")
        },
        {
            ["id"] = "forcePlayerLink",
            ["label"] = gmInte.getTranslation("admin.force_player_link", "Force Player Verif"),
            ["description"] = gmInte.getTranslation("admin.force_player_link_description", "Force player verification."),
            ["type"] = "checkbox",
            ["reloadOnEdit"] = true,
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["category"] = gmInte.getTranslation("admin.trust_safety", "Trust & Safety")
        },
        {
            ["id"] = "supportLink",
            ["label"] = gmInte.getTranslation("admin.support_link", "Support Link"),
            ["description"] = gmInte.getTranslation("admin.support_link_description", "Support Link found on the webpanel."),
            ["type"] = "textEntry",
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["onEditDelay"] = 0.5,
            ["category"] = gmInte.getTranslation("admin.trust_safety", "Trust & Safety")
        },
        {
            ["id"] = "verifyFamilySharing",
            ["label"] = gmInte.getTranslation("admin.verifyFamilySharing", "Block Family Sharing"),
            ["description"] = gmInte.getTranslation("admin.verifyFamilySharing_description", "Block family sharing players."),
            ["type"] = "checkbox",
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["category"] = gmInte.getTranslation("admin.trust_safety", "Trust & Safety")
        },
        {
            ["id"] = "verifyOnJoin",
            ["label"] = gmInte.getTranslation("admin.verify_on_join", "Verify on Join"),
            ["description"] = gmInte.getTranslation("admin.verify_on_join_description", "Verify the player when they join the server or on player ready."),
            ["type"] = "checkbox",
            ["condition"] = function(data) return data.forcePlayerLink end,
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["category"] = gmInte.getTranslation("admin.trust_safety", "Trust & Safety")
        },
        {
            ["id"] = "verifyOnReadyKickTime",
            ["label"] = gmInte.getTranslation("admin.verify_on_ready_kick_time", "Kick Time if not Verified"),
            ["description"] = gmInte.getTranslation("admin.verify_on_ready_kick_time_description", "Time in seconds before kicking a player that is not verified."),
            ["type"] = "textEntry",
            ["condition"] = function(data) return data.forcePlayerLink end,
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["category"] = gmInte.getTranslation("admin.trust_safety", "Trust & Safety")
        },
        {
            ["id"] = "clientBranch",
            ["label"] = gmInte.getTranslation("admin.client_force_branch", "Client Force Branch"),
            ["description"] = gmInte.getTranslation("admin.client_force_branch_description", "The branch of the addon that the clients should use."),
            ["type"] = "combo",
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["category"] = gmInte.getTranslation("admin.trust_safety", "Trust & Safety"),
            ["values"] = {
                ["any"] = "Any",
                ["dev"] = "Dev",
                ["prerelease"] = "Prerelease",
                ["x86-64"] = "x86-64",
            }
        },
        {
            ["id"] = "debug",
            ["label"] = gmInte.getTranslation("admin.debug", "Debug"),
            ["description"] = gmInte.getTranslation("admin.debug_description", "Activate or deactivate debug mode."),
            ["type"] = "checkbox",
            ["value"] = function(setting, value) return value end,
            ["position"] = 1,
            ["onEdit"] = function(setting, value) saveConfig(setting, value) end,
            ["category"] = gmInte.getTranslation("admin.advanced", "Advanced")
        },
        {
            ["id"] = "websocketFQDN",
            ["label"] = gmInte.getTranslation("admin.websocket_fqdn", "Websocket FQDN"),
            ["description"] = gmInte.getTranslation("admin.websocket_fqdn_description", "Websocket FQDN that will be used for the Websocket connection."),
            ["type"] = "textEntry",
            ["value"] = function(setting, value) return value end,
            ["resetIfEmpty"] = true,
            ["defaultValue"] = "ws.gmod-integration.com",
            ["onEdit"] = function(setting, value)
                if !value || value == "" then return end
                saveConfig(setting, value)
            end,
            ["onEditDelay"] = 0.5,
            ["category"] = gmInte.getTranslation("admin.advanced", "Advanced")
        },
        {
            ["id"] = "apiFQDN",
            ["label"] = gmInte.getTranslation("admin.api_fqdn", "API FQDN"),
            ["description"] = gmInte.getTranslation("admin.api_fqdn_description", "API FQDN that will be used for the API connection."),
            ["type"] = "textEntry",
            ["resetIfEmpty"] = true,
            ["defaultValue"] = "api.gmod-integration.com",
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value)
                if !value || value == "" then return end
                saveConfig(setting, value)
            end,
            ["onEditDelay"] = 0.5,
            ["category"] = gmInte.getTranslation("admin.advanced", "Advanced")
        },
        {
            ["id"] = "logTimestamp",
            ["label"] = gmInte.getTranslation("admin.internal_log_format", "Internal Log Format"),
            ["description"] = gmInte.getTranslation("admin.internal_log_format_description", "The timestamp format of the logs."),
            ["type"] = "textEntry",
            ["resetIfEmpty"] = true,
            ["defaultValue"] = "%Y-%m-%d %H:%M:%S",
            ["value"] = function(setting, value) return value end,
            ["onEdit"] = function(setting, value)
                if !value || value == "" then return end
                saveConfig(setting, value)
            end,
            ["onEditDelay"] = 0.5,
            ["category"] = gmInte.getTranslation("admin.advanced", "Advanced")
        },
    }

    local buttonsInfo = {
        {
            ["label"] = gmInte.getTranslation("admin.link.open_webpanel", "Open Webpanel"),
            ["func"] = function() gui.OpenURL("https://gmod-integration.com/dashboard/guilds") end,
        },
        {
            ["label"] = gmInte.getTranslation("admin.link.test_connection", "Test Connection"),
            ["func"] = function() gmInte.SendNet("testConnection") end,
        },
        {
            ["label"] = gmInte.getTranslation("admin.link.buy_premium", "Buy Premium"),
            ["func"] = function() gui.OpenURL("https://gmod-integration.com/premium") end,
        },
        {
            ["label"] = gmInte.getTranslation("admin.link.install_websocket", "Install Websocket"),
            ["condition"] = function(data) return !data.websocket end,
            ["func"] = function() gui.OpenURL("https://github.com/FredyH/GWSockets/releases") end,
        },
    }

    local needRestart = false
    if gmInte.openAdminPanel then return end
    gmInte.openAdminPanel = true
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, (600 / 1080) * ScrH())
    frame:Center()
    frame:SetTitle(gmInte.getFrameName(gmInte.getTranslation("admin.server_config", "Server Config")))
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()
    gmInte.applyPaint(frame)
    local scrollPanel = vgui.Create("DScrollPanel", frame)
    scrollPanel:Dock(FILL)
    local messagePanel = vgui.Create("DPanel", scrollPanel)
    messagePanel:Dock(TOP)
    messagePanel:SetSize(300, 80)
    messagePanel:DockMargin(10, 0, 10, 10)
    messagePanel:SetBackgroundColor(Color(0, 0, 0, 0))
    local messageLabel = vgui.Create("DLabel", messagePanel)
    messageLabel:Dock(FILL)
    messageLabel:SetText(gmInte.getTranslation("admin.server_id_description2", "Here you can configure your server settings.\nServer ID and Token are available on the webpanel in the server settings.\nThe documentation is available at {1}\nIf you need help, please contact us on our discord server.", "https://docs.gmod-integration.com"))
    messageLabel:SetWrap(true)
    for k, catName in ipairs(configCat) do
        local collapsibleCategory = vgui.Create("DCollapsibleCategory", scrollPanel)
        collapsibleCategory:Dock(TOP)
        collapsibleCategory:DockMargin(10, 0, 10, 10)
        collapsibleCategory:SetLabel(catName)
        collapsibleCategory:SetExpanded(catName != gmInte.getTranslation("admin.advanced", "Advanced"))
        gmInte.applyPaint(collapsibleCategory)
        local configList = vgui.Create("DPanelList", collapsibleCategory)
        configList:Dock(FILL)
        configList:SetSpacing(5)
        configList:EnableHorizontal(false)
        configList:EnableVerticalScrollbar(false)
        collapsibleCategory:SetContents(configList)
        local categoryConfig = {}
        for k, v in ipairs(possibleConfig) do
            if v.category == catName then table.insert(categoryConfig, v) end
        end

        // Sort by position
        table.sort(categoryConfig, function(a, b) return (a.position || 0) < (b.position || 0) end)
        for k, actualConfig in ipairs(categoryConfig) do
            if actualConfig.condition && !actualConfig.condition(data) then continue end
            local panel = vgui.Create("DPanel", configList)
            panel:Dock(TOP)
            panel:SetSize(300, 25)
            panel:SetBackgroundColor(Color(0, 0, 0, 0))
            local label = vgui.Create("DLabel", panel)
            label:Dock(LEFT)
            label:SetSize(190, 25)
            label:SetText(actualConfig.label)
            label:SetContentAlignment(4)
            local input
            if actualConfig.type == "textEntry" then
                input = vgui.Create("DTextEntry", panel)
                local value = actualConfig.value(actualConfig.id, data[actualConfig.id] || "")
                if actualConfig.secret then
                    input:SetText(gmInte.getTranslation("admin.click_to_show", "*** Click to show ***"))
                else
                    input:SetText(value)
                end

                input.OnGetFocus = function(self) if actualConfig.secret then self:SetText(value) end end
                input.OnLoseFocus = function(self) if actualConfig.secret then self:SetText(gmInte.getTranslation("admin.click_to_show", "*** Click to show ***")) end end
                local isLastID = 0
                input.OnChange = function(self)
                    if actualConfig.resetIfEmpty && self:GetValue() == "" && actualConfig.defaultValue then
                        self:SetText(actualConfig.defaultValue)
                        return
                    end

                    isLastID = isLastID + 1
                    local isLocalLastID = isLastID
                    timer.Simple(actualConfig.onEditDelay || 0.5, function() if isLocalLastID == isLastID then actualConfig.onEdit(actualConfig.id, self:GetValue()) end end)
                end
            elseif actualConfig.type == "checkbox" then
                input = vgui.Create("DComboBox", panel)
                if actualConfig.condition && !actualConfig.condition(data) then input:SetEnabled(false) end
                input:AddChoice(gmInte.getTranslation("admin.enabled", "Enabled"))
                input:AddChoice(gmInte.getTranslation("admin.disabled", "Disabled"))
                input:SetText(actualConfig.value(actualConfig.id, data[actualConfig.id]) && gmInte.getTranslation("admin.enabled", "Enabled") || gmInte.getTranslation("admin.disabled", "Disabled"))
                input.OnSelect = function(self, index, value)
                    if actualConfig.restart then needRestart = true end
                    actualConfig.onEdit(actualConfig.id, value == gmInte.getTranslation("admin.enabled", "Enabled") && true || false)
                    if actualConfig.reloadOnEdit then
                        frame:Close()
                        RunConsoleCommand("gmi_admin")
                    end
                end
            elseif actualConfig.type == "combo" then
                input = vgui.Create("DComboBox", panel)
                if actualConfig.condition && !actualConfig.condition(data) then input:SetEnabled(false) end
                local posibilities = {}
                for k, v in pairs(actualConfig.values) do
                    table.insert(posibilities, k)
                    input:AddChoice(v, k)
                end

                input:SetText(actualConfig.values[data[actualConfig.id]] || actualConfig.values[actualConfig.defaultValue] || "<nil>")
                input.OnSelect = function(self, index, value)
                    if actualConfig.restart then needRestart = true end
                    actualConfig.onEdit(actualConfig.id, posibilities[index])
                    if actualConfig.reloadOnEdit then
                        frame:Close()
                        RunConsoleCommand("gmi_admin")
                    end
                end
            end

            input:Dock(FILL)
            input:SetSize(150, 25)
            if actualConfig.description then
                if actualConfig.websocket && !data.websocket then actualConfig.description = actualConfig.description .. gmInte.getTranslation("admin.websocket_required", "\n\nThis feature require a websocket connection to work properly.") end
                if actualConfig.disable then actualConfig.description = actualConfig.description .. gmInte.getTranslation("admin.feature_soon", "\n\nThis feature will be available soon.") end
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
    for k, v in ipairs(buttonsInfo) do
        if v.condition && !v.condition(data) then continue end
        local button = vgui.Create("DButton")
        button:SetText(v.label)
        button.DoClick = function() v.func(data) end
        gmInte.applyPaint(button)
        button:SetSize(buttonGrid:GetColWide() - 10, buttonGrid:GetRowHeight() - 10)
        buttonGrid:AddItem(button)
        buttonsCount = buttonsCount + 1
    end

    if buttonsCount % 2 == 1 then
        local lastButton = buttonGrid:GetItems()[buttonsCount]
        lastButton:SetWide(frame:GetWide() - 20)
    end

    frame.OnClose = function()
        gmInte.openAdminPanel = false
        if needRestart then gmInte.needRestart() end
    end
end

local alreadySkipDll = false
function gmInte.openDllInstall()
    if !LocalPlayer():gmIntIsAdmin() then return end
    if alreadySkipDll then return end
    alreadySkipDll = true
    local frame = vgui.Create("DFrame")
    frame:SetSize(400, 250)
    frame:Center()
    frame:SetTitle(gmInte.getFrameName(gmInte.getTranslation("admin.dll_install", "DLL Install")))
    frame:SetDraggable(true)
    frame:ShowCloseButton(true)
    frame:MakePopup()
    gmInte.applyPaint(frame)
    local messageLabel = vgui.Create("DLabel", frame)
    messageLabel:Dock(FILL)
    messageLabel:SetText(gmInte.getTranslation("admin.dll_install_problem", "The Gmod Integration DLL is missing!\n\nWithout this DLL, some features will not work correctly, including authentication and advanced integration.") .. "\n\n" .. gmInte.getTranslation("admin.dll_install_description", "Install:\n1. Download 'gmsv_gmod_integration_loader_{1}.dll' from: {2}\n2. Move it to the 'garrysmod/lua/bin' folder.\n3. Restart your server.", gmInte.serverOS, "https://github.com/gmod-integration/auto-loader/releases/latest/download/gmsv_gmod_integration_loader_" .. gmInte.serverOS .. ".dll"))
    messageLabel:SetContentAlignment(5)
    messageLabel:SetWrap(true)
    local buttonGrid = vgui.Create("DGrid", frame)
    buttonGrid:Dock(BOTTOM)
    buttonGrid:DockMargin(5, 10, 5, 5)
    buttonGrid:SetCols(1)
    buttonGrid:SetColWide(frame:GetWide() - 10)
    buttonGrid:SetRowHeight(35)
    local button = vgui.Create("DButton")
    button:SetText(gmInte.getTranslation("admin.dll_install_button", "Install DLL"))
    button.DoClick = function()
        frame:Close()
        gui.OpenURL("https://github.com/gmod-integration/auto-loader/releases/latest/download/gmsv_gmod_integration_loader_" .. gmInte.serverOS .. ".dll")
    end

    button:SetSize(buttonGrid:GetColWide() - 10, buttonGrid:GetRowHeight())
    gmInte.applyPaint(button)
    buttonGrid:AddItem(button)
end

function gmInte.openAdminConfig()
    if !LocalPlayer():gmIntIsAdmin() then
        gmInte.chatAddText(Color(228, 81, 81), gmInte.getTranslation("chat.missing_permissions", "You do not have permission to do this action."))
        return
    end

    gmInte.SendNet("getConfig")
end

function gmInte.showTestConnection(data)
    if data && data.id then
        gmInte.chatAddText(Color(89, 194, 89), gmInte.getTranslation("chat.authentication_success", "Successfully Authenticated"), Color(255, 255, 255), gmInte.getTranslation("chat.server_link", ", server linked as {1}.", data.name))
    else
        gmInte.chatAddText(Color(228, 81, 81), gmInte.getTranslation("chat.authentication_failed", "Failed to Authenticate"), Color(255, 255, 255), gmInte.getTranslation("chat.server_fail", ", check your ID and Token."))
    end
end

concommand.Add("gmod_integration_admin", function() gmInte.SendNet("getConfig") end)
concommand.Add("gmi_admin", function() gmInte.SendNet("getConfig") end)
hook.Add("OnPlayerChat", "gmInte:OnPlayerChat:AdminCmd", function(ply, strText, bTeamOnly, bPlayerIsDead)
    if ply != LocalPlayer() then return end
    strText = string.lower(strText)
    if strText == "/gmi" || strText == "!gmi" then
        gmInte.openAdminConfig()
        return true
    end
end)