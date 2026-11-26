function gmInte.SendNet(id, args, func)
    local encoded = util.TableToJSON(args || {})
    if !encoded || #encoded > 60000 then return false end
    net.Start("gmIntegration")
    net.WriteString(id)
    net.WriteString(encoded)
    if func then func() end
    net.SendToServer()
    return true
end

local netReceive = {
    ["wsRelayDiscordChat"] = function(data) gmInte.discordSyncChatPly(data) end,
    ["adminConfig"] = function(data) gmInte.openConfigMenu(data) end,
    ["testApiConnection"] = function(data) gmInte.showTestConnection(data) end,
    ["publicConfig"] = function(data)
        gmInte.config = table.Merge(gmInte.config, data.config)
        gmInte.version = data.other.version
        gmInte.loadTranslations()
        if gmInte.config.clientBranch != "any" && gmInte.config.clientBranch != BRANCH then gmInte.openWrongBranchPopup() end
        if !data.other.aprovedCredentials then RunConsoleCommand("gmod_integration_admin") end
    end,
    ["chatColorMessage"] = function(data) gmInte.chatAddTextFromTable(data) end,
    ["openVerifPopup"] = function() gmInte.openVerifPopup() end,
    ["apiRelayResponse"] = function(data) gmInte.receiveClientAPIResponse(data) end,
    ["notEditableConfig"] = function() gmInte.openDisabledConfig() end,
}

net.Receive("gmIntegration", function(len)
    if len > 60000 * 8 then return end
    local id = net.ReadString()
    if !netReceive[id] || #id > 64 then return end
    local args = gmInte.decodeBoundedNetJSON(net.ReadString())
    if !istable(args) then return end
    netReceive[id](args)
    if gmInte.config.debug && id != "apiRelayResponse" then
        gmInte.log("[net] Received net message: " .. id)
    end
end)
