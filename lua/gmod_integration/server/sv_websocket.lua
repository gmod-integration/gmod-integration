//
// WebSocket
//

if (!GWSockets) then return gmInte.logError("GWSockets not found!") end

require("gwsockets")

local socket = GWSockets.createWebSocket("wss://ws.gmod-integration.com")

function socket:onMessage(txt)
    print("Received: ", txt)
end

function socket:onError(txt)
    print("Error: ", txt)
end

-- We start writing only after being connected here. Technically this is not required as this library
-- just waits until the socket is connected before sending, but it's probably good practice
function socket:onConnected()
    print("Connected to echo server")
    // say hi
    socket:write("Hello from GMod!")
    timer.Simple(1, function()
        socket:write("ping")
    end)

    timer.Simple(2, function()
        timer.Remove("SocketWriteTimer")
        -- Even if some of the messages have not reached the other side yet, this type of close makes sure
        -- to only close the socket once all queued messages have been received by the peer.
        socket:close()
    end)
end

// log on message
function socket:onMessage(txt)
    print("Received: ", txt)
end

function socket:onDisconnected()
    print("WebSocket disconnected")
end

socket:open()