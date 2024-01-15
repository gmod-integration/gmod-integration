//
// WebSocket
//

// TODO made a proper system to detect if the server need to be connected to the websocket
if (!gmInte.config.syncChat && !gmInte.config.websocket) then
    gmInte.log("WebSocket is disabled", true)
    return
end

if (!GWSockets) then return gmInte.logError("GWSockets is not installed! Please install it from https://github.com/FredyH/GWSockets") end

require("gwsockets")

local socket = GWSockets.createWebSocket("wss://ws.gmod-integration.com")

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
    if (gmInte.config.debug) then
        gmInte.log("WebSocket Message: " .. txt, true)
    end
    if (gmInte[data.method]) then
        gmInte[data.method](data)
    else
        gmInte.logError("WebSocket Message: " .. txt .. " is not a valid method !")
    end
end

function socket:onDisconnected()
    gmInte.log("WebSocket Disconnected", true)
end

function socket:onError(txt)
    gmInte.logError("WebSocket Error: " .. txt)
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