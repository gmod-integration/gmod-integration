//
// Methods
//

function gmInte.sendStatus()
    gmInte.http.post("/servers/:serverID/status", gmInte.getServerFormat())
end

-- function gmInte.serverStart()
--     gmInte.http.post("/start", gmInte.getServerFormat())
-- end

function gmInte.serverShutDown()
    gmInte.http.post("/servers/:serverID/shutdown")
end

//
// Timers
//

timer.Create("gmInte.sendStatus", 300, 0, function()
    gmInte.sendStatus()
end)

//
// Hooks
//

hook.Add("Initialize", "gmInte:Server:Initialize:SendStatus", function()
    timer.Simple(1, function()
        -- gmInte.serverStart()
        gmInte.sendStatus()
    end)
end)

hook.Add("ShutDown", "gmInte:Server:ShutDown:SendStatus", function()
    gmInte.serverShutDown()
end)