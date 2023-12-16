local function saveConfig(setting, value)
    gmInte.SendNet("3", {
        [setting] = value
    })
end

local configCat = {
    "Authentication",
    "Main",
    "Trust & Safety"
}

local possibleConfig = {
    ["id"] = {
        ["label"] = "ID",
        ["description"] = "Your server ID. You can find it on the webpanel.",
        ["type"] = "textEntry",
        ["value"] = function(value)
            return value
        end,
        ["onEdit"] = function(value)
            saveConfig("id", value)
        end,
        ["onEditDelay"] = 0.5,
        ["category"] = "Authentication"
    },
    ["token"] = {
        ["label"] = "Token",
        ["description"] = "Your server Token. You can find it on the webpanel.",
        ["type"] = "textEntry",
        ["value"] = function(value)
            return value
        end,
        ["onEdit"] = function(value)
            saveConfig("token", value)
        end,
        ["onEditDelay"] = 0.5,
        ["category"] = "Authentication"
    },
    ["logs"] = {
        ["label"] = "Logs",
        ["description"] = "Activate or deactivate the logs.",
        ["type"] = "checkbox",
        ["value"] = function(value)
            return value
        end,
        ["onEdit"] = function(value)
            saveConfig("disableLog", value == "Enabled" && true || false)
        end,
        ["category"] = "Main"
    },
    ["filterOnBan"] = {
        ["label"] = "Block Discord Ban Player",
        ["description"] = "Block players that are banned on the discord server.",
        ["type"] = "checkbox",
        ["value"] = function(value)
            return value
        end,
        ["onEdit"] = function(value)
            saveConfig("disableLog", value == "Enabled" && true || false)
        end,
        ["category"] = "Trust & Safety"
    },
    ["filterOnTrust"] = {
        ["label"] = "Block UnTrust Player",
        ["description"] = "",
        ["type"] = "checkbox",
        ["value"] = function(value)
            return value
        end,
        ["onEdit"] = function(value)
            saveConfig("disableLog", value == "Enabled" && true || false)
        end,
        ["category"] = "Trust & Safety"
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
        ["try"] = "Test Connection",
        ["func"] = function()
            gmInte.SendNet("1")
        end,
    },
    {
        ["try"] = "Tdest Connection",
        ["func"] = function()
            gmInte.SendNet("1")
        end,
    }
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
    messagePanel:SetBackgroundColor(Color(0, 0, 0, 0))

    local messageLabel = vgui.Create("DLabel", messagePanel)
    messageLabel:Dock(FILL)
    messageLabel:SetText("This config is superior to the webpanel config. If you change something here you can override the webpanel config. For example if you disable the logs here, the logs will not be available on the webpanel.")
    messageLabel:SetWrap(true)


    for k, catName in pairs(configCat) do
        // create DCollapsibleCategory
        local collapsibleCategory = vgui.Create("DCollapsibleCategory", scrollPanel)
        collapsibleCategory:Dock(TOP)
        collapsibleCategory:DockMargin(0, 0, 0, 5)
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
                    input:SetText(v.value(data[k]))
                    local isLastID = 0
                    input.OnChange = function(self)
                        isLastID = isLastID + 1
                        local isLocalLastID = isLastID
                        timer.Simple(v.onEditDelay || 0.5, function()
                            if isLocalLastID == isLastID then
                                v.onEdit(self:GetValue())
                            end
                        end)
                    end
                elseif v.type == "checkbox" then
                    input = vgui.Create("DComboBox", panel)
                    input:AddChoice("Enabled")
                    input:AddChoice("Disabled")
                    input:SetText(v.value(data[k]) && "Enabled" || "Disabled")
                    input.OnSelect = function(self, index, value)
                        v.onEdit(value)
                    end
                end

                input:Dock(FILL)
                input:SetSize(150, 25)

                if v.description then
                    panel:SetTooltip(v.description)
                end

                configList:AddItem(panel)
            end
        end
    end

    local buttonsPanel = vgui.Create("DPanel", frame)
    buttonsPanel:Dock(BOTTOM)
    buttonsPanel:SetSize(300, 50)
    buttonsPanel:SetBackgroundColor(Color(0, 0, 0, 0))

    local buttonRows = {}
    local currentRow = nil

    for k, v in pairs(buttonsInfo) do
        if k % 2 == 1 then
            currentRow = vgui.Create("DPanel", buttonsPanel)
            currentRow:Dock(TOP)
            currentRow:SetSize(300, 25)
            currentRow:SetBackgroundColor(Color(0, 0, 0, 0))
            table.insert(buttonRows, currentRow)
        end

        local button = vgui.Create("DButton", currentRow)
        button:Dock(k % 2 == 1 && LEFT || RIGHT)
        button:SetText(v.label or v.try)
        button:SetWide(button:GetParent():GetWide() / 2)

        button.DoClick = function()
            v.func()
        end
    end
end

// Add on Desktop Widgets
-- Vérifie si l'interface utilisateur de widgets existe et la crée si ce n'est pas le cas
if not MyWidget then
    MyWidget = {}
end

-- Fonction pour créer le widget
function MyWidget.CreateWidget()
    local frame = vgui.Create("DFrame")
    frame:SetSize(200, 100)
    frame:SetTitle("Mon Widget")
    frame:MakePopup()

    -- Ajouter d'autres éléments à votre widget ici

    return frame
end

list.Set("DesktopWindows", "GmodIntegration:DesktopWindows", {
	icon = "icon64/gmodintegration.png",
	title = "Gmod Integration",
	width = 100,
	height = 100,
	onewindow = true,
	init = function(icon, window)
		window:Close()
        gmInte.openAdminConfig()
	end
	}
)