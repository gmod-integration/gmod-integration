//
// WebSocket
//

local useWebsocket = false
local websocketFeature = {
    'syncChat',
    'websocket',
}

for k, v in pairs(websocketFeature) do
    if (gmInte.config[v]) then
        useWebsocket = true
    end
end

if (!useWebsocket) then
    return gmInte.log("WebSocket is not used")
end

require("gwsockets")

if (!GWSockets) then
    timer.Simple(1, function()
        if (!GWSockets) then
            gmInte.logError("GWSockets is not installed! Please install it from https://github.com/FredyH/GWSockets/releases")
        end
    end)
    return
end

local function getWebSocketURL()
    return "wss://" .. gmInte.config.websocketFQDN
end

local socket = GWSockets.createWebSocket(getWebSocketURL())

// Authentication
socket:setHeader("id", gmInte.config.id)
socket:setHeader("token", gmInte.config.token)

function socket:onConnected()
    gmInte.log("WebSocket Connected", true)
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
    gmInte.log("WebSocket Disconnected", true)
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