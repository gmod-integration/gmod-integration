local function websocketDLLExist()
    local files, _ = file.Find("lua/bin/*", "GAME")
    for k, v in ipairs(files) do
        if v:find("gwsockets") then return true end
    end
    return false
end

if !websocketDLLExist() then
    timer.Simple(60, function()
        gmInte.logHint("GWSockets is not installed !")
        gmInte.logHint("Please read the installation guide: https://docs.gmod-integration.com/getting-started/installation#dll")
    end)
    return
end

require("gwsockets")
local function getWebSocketURL()
    local method = gmInte.isPrivateIP(gmInte.config.websocketFQDN) && "ws" || "wss"
    return method .. "://" .. gmInte.config.websocketFQDN
end

function gmInte.setupWebSocket()
    local callbacks_ = {}
    gmInte.websocket = GWSockets.createWebSocket(getWebSocketURL())
    gmInte.websocket:setHeader("id", gmInte.config.id)
    gmInte.websocket:setHeader("token", gmInte.config.token)
    gmInte.websocket:open()
    function gmInte.websocket:onConnected()
        gmInte.log("WebSocket Connected", true)
    end

    function gmInte.websocket:onMessage(txt)
        gmInte.log("WebSocket Message: " .. txt, true)
        local data = util.JSONToTable(txt)
        if gmInte[data.method] then
            gmInte[data.method](data)
        elseif data.id && callbacks_[data.id] then
            local callback = callbacks_[data.id]
            callbacks_[data.id] = nil
            if data.error then
                gmInte.logError("WebSocket Error: " .. data.error, true)
                callback(false, data.error)
            else
                callback(true, data.data)
            end
        else
            gmInte.logError("WebSocket Message: " .. txt .. " is not a valid method !", true)
        end
    end

    function gmInte.websocket:onDisconnected()
        gmInte.log("WebSocket Disconnected", true)
    end

    function gmInte.websocket:onError(txt)
        gmInte.logError("WebSocket Error: " .. txt, true)
    end

    function gmInte.websocket:send(method, data, callback, hidePrint)
        if !self:isConnected() then
            if !hidePrint then
                gmInte.logError("WebSocket is not connected, cannot send data", true)
            end
            return
        end

        local id = tostring(SysTime()) .. "-" .. gmInte.generateRandomString(8)

        local packet = {
            method = method,
            data = data,
            id = id
        }

        if callback then
            callbacks_[id] = callback
        end
        
        if !hidePrint then
            gmInte.log("WebSocket Send: " .. util.TableToJSON(packet), true)
        end
        self:write(util.TableToJSON(packet))
    end
end

timer.Create("gmInte:WebSocket:CheckConnection", 4, 0, function()
    if (!gmInte.websocket || !gmInte.websocket:isConnected()) && gmInte.aprovedCredentials then
        gmInte.log("WebSocket is not connected, trying to connect", true)
        gmInte.setupWebSocket()
    end
end)

hook.Add("GmodIntegration:Websocket:Restart", "gmInte:WebSocket:Restart", function() gmInte.setupWebSocket() end)
hook.Add("InitPostEntity", "gmInte:ServerReady:WebSocket", function() timer.Simple(1, function() gmInte.setupWebSocket() end) end)