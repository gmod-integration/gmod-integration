function gmInte.SendNet(id, args, func)
    net.Start("gmIntegration")
    net.WriteString(id)
    net.WriteString(util.TableToJSON(args || {}))
    if func then func() end
    net.SendToServer()
end

local netReceive = {
    ["wsRelayDiscordChat"] = function(data) gmInte.discordSyncChatPly(data) end,
    ["adminConfig"] = function(data) gmInte.openConfigMenu(data) end,
    ["testApiConnection"] = function(data) gmInte.showTestConnection(data) end,
    ["publicConfig"] = function(data)
        gmInte.config = table.Merge(gmInte.config, data.config)
        gmInte.version = data.other.version
        gmInte.dllExists = data.other.dllExists
        if !gmInte.dllExists then gmInte.openDllInstall() end
        gmInte.loadTranslations()
        if gmInte.config.clientBranch != "any" && gmInte.config.clientBranch != BRANCH then gmInte.openWrongBranchPopup() end
        if !data.other.aprovedCredentials then RunConsoleCommand("gmod_integration_admin") end
    end,
    ["chatColorMessage"] = function(data) gmInte.chatAddTextFromTable(data) end,
    ["openVerifPopup"] = function() gmInte.openVerifPopup() end,
    ["savePlayerToken"] = function(data) gmInte.config.token = data.token end,
    ["notEditableConfig"] = function() gmInte.openDisabledConfig() end,
}

net.Receive("gmIntegration", function()
    local id = net.ReadString()
    local args = util.JSONToTable(net.ReadString())
    if !netReceive[id] then return end
    netReceive[id](args)
    if gmInte.config.debug then
        gmInte.log("[net] Received net message: " .. id)
        gmInte.log("[net] Data: " .. util.TableToJSON(args))
    end
end)