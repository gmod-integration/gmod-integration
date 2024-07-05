local function websocketDLLExist()
    local files, _ = file.Find("lua/bin/*", "GAME")
    for k, v in pairs(files) do
        if v:find("gwsockets") then return true end
    end
    return false
end

if !websocketDLLExist() then
    timer.Simple(4, function()
        gmInte.logHint("GWSockets is not installed !, Syncronize feature will not work !")
        gmInte.logHint("Please install it from https://github.com/FredyH/GWSockets/releases")
    end)
    return
end

require("gwsockets")
local function getWebSocketURL()
    local method = gmInte.isPrivateIP(gmInte.config.websocketFQDN) && "ws" || "wss"
    return method .. "://" .. gmInte.config.websocketFQDN
end

local socket = GWSockets.createWebSocket(getWebSocketURL())
socket:setHeader("id", gmInte.config.id)
socket:setHeader("token", gmInte.config.token)
function gmInte.resetWebSocket()
    socket:closeNow()
    socket = GWSockets.createWebSocket(getWebSocketURL())
    socket:setHeader("id", gmInte.config.id)
    socket:setHeader("token", gmInte.config.token)
end

local hasConnected = false
function socket:onConnected()
    hasConnected = true
    gmInte.log("WebSocket Connected", true)
end

function socket:onMessage(txt)
    gmInte.log("WebSocket Message: " .. txt, true)
    local data = util.JSONToTable(txt)
    if gmInte[data.method] then
        gmInte[data.method](data)
    else
        gmInte.logError("WebSocket Message: " .. txt .. " is not a valid method !", true)
    end
end

function socket:onDisconnected()
    if hasConnected then
        hasConnected = false
        gmInte.log("WebSocket Disconnected", true)
    else
        gmInte.logError("WebSocket Connection Failed", true)
    end
end

function socket:onError(txt)
    gmInte.logError("WebSocket Error: " .. txt, true)
end

timer.Create("gmInte:WebSocket:CheckConnection", 4, 0, function()
    if !socket:isConnected() then
        gmInte.resetWebSocket()
        socket:open()
    end
end)

hook.Add("InitPostEntity", "gmInte:ServerReady:WebSocket", function()
    timer.Simple(1, function()
        gmInte.resetWebSocket()
        socket:open()
    end)
end)