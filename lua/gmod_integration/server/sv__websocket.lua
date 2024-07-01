//
// WebSocket
//

local function websocketDLLExist()
    local files, _ = file.Find("lua/bin/*", "GAME")
    for k, v in pairs(files) do
        if (v:find("gwsockets")) then
            return true
        end
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

// Authentication
socket:setHeader("id", gmInte.config.id)
socket:setHeader("token", gmInte.config.token)

local hasConnected = false
function socket:onConnected()
    hasConnected = true
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
    if (hasConnected) then
        gmInte.log("WebSocket Disconnected", true)
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
    -- Check if the API is undergoing an update
    if gmInte.isApiUpdating then
        if socket:isConnected() then
            gmInte.log("API Update detected, closing WebSocket connection.", true)
            socket:close()
        end
        return
    end

    if socket:isConnected() then
        -- Connection is already open, no need to do anything
        -- Optionally, you can log this or handle it differently
    else
        socket:open()
    end
end)

-- Example function to set the API update status
-- This could be triggered by some condition or external input
function gmInte.setApiUpdateStatus(isUpdating)
    gmInte.isApiUpdating = isUpdating
    if isUpdating then
        gmInte.log("API Update starting, WebSocket connections will be managed accordingly.", true)
    else
        gmInte.log("API Update completed, WebSocket connections can resume normal operation.", true)
    end
end