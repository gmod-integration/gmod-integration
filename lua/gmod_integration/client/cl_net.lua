local netSend = {
    ["ready"] = 0,
    ["testConnection"] = 1,
    ["getConfig"] = 2,
    ["saveConfig"] = 3,
    ["takeScreenShot"] = 4,
    ["restartMap"] = 5,
    ["verifyMe"] = 6,
}

function gmInte.SendNet(id, args, func)
    net.Start("gmIntegration")
    net.WriteUInt(netSend[id], 8)
    net.WriteString(util.TableToJSON(args || {}))
    if func then func() end
    net.SendToServer()
end

local netReceive = {
    [1] = function(data) gmInte.discordSyncChatPly(data) end,
    [2] = function(data) gmInte.openConfigMenu(data) end,
    [3] = function(data) gmInte.showTestConnection(data) end,
    [5] = function(data)
        gmInte.config = table.Merge(gmInte.config, data.config)
        gmInte.version = data.other.version
        if !data.other.aprovedCredentials then RunConsoleCommand("gmod_integration_admin") end
    end,
    [6] = function(data) gmInte.chatAddText(data) end,
    [7] = function() gmInte.openVerifPopup() end,
    [8] = function(data) gmInte.config.token = data.token end
}

net.Receive("gmIntegration", function()
    local id = net.ReadUInt(8)
    local args = util.JSONToTable(net.ReadString())
    if netReceive[id] then netReceive[id](args) end
end)