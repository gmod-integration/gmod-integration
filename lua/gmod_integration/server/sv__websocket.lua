//
// WebSocket
//

if !file.Exists("bin/gm_gwsockets.dll", "LUA") then
    timer.Simple(4, function()
        gmInte.logHint("GWSockets is not installed !, Syncronize feature will not work !")
        gmInte.logHint("Please install it from https://github.com/FredyH/GWSockets/releases")
    end)
    return
end

require("gwsockets")

local function getWebSocketURL()
    return "wss://" .. gmInte.config.websocketFQDN
end

local socket = GWSockets.createWebSocket(getWebSocketURL())

// Authentication
socket:setHeader("id", gmInte.config.id)
socket:setHeader("token", gmInte.config.token)

local hasConnected = false
function socket:onConnected()
    hasConnected = true
    gmInte.log("WebSocket Connected")
end

// log on message
function socket:onMessage(txt)
    gmInte.log("WebSocket Message: " .. txt, true)

    local data = util.JSONToTable(txt)
    if (gmInte[data.method]) then
        gmInte[data.method](data)
    else
        gmInte.logError("WebSocket Message: " .. txt .. " is not a valid method !", true)
    end
end

function socket:onDisconnected()
    if (hasConnected) then
        gmInte.log("WebSocket Disconnected")
    else
        gmInte.logError("WebSocket Connection Failed", true)
    end
end

function socket:onError(txt)
    gmInte.logError("WebSocket Error: " .. txt, true)
end

function gmInte.websocketWrite(data)
    if (!socket:isConnected()) then
        socket:open()
    end
    socket:write(util.TableToJSON(data || {}))
end

timer.Create("gmInte:WebSocket:CheckConnection", 4, 0, function()
    if (!socket:isConnected()) then
        socket:open()
    end
end)

hook.Add("InitPostEntity", "gmInte:ServerReady:WebSocket", function()
    timer.Simple(1, function()
        socket:open()
    end)
end)