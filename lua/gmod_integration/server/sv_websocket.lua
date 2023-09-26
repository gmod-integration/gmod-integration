//
// WebSocket
//

if (!gmInte.config.websocket) then return end

require("gwsockets")

if (!GWSockets) then return gmInte.logError("GWSockets is not installed! Please install it from https://github.com/FredyH/GWSockets") end

local socket = GWSockets.createWebSocket("wss://ws.gmod-integration.com")

// Authentication
socket:setHeader("id", gmInte.config.id)
socket:setHeader("token", gmInte.config.token)

function socket:onConnected()
    gmInte.log("WebSocket connected", true)
end

// log on message
function socket:onMessage(txt)
    gmInte.log("WebSocket Message: " .. txt, true)
end

function socket:onDisconnected()
    gmInte.log("WebSocket disconnected", true)
end

function socket:onError(txt)
    gmInte.logError("WebSocket Error: " .. txt)
end

socket:open()