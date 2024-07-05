function gmInte.sendStatus()
    gmInte.http.post("/servers/:serverID/status", gmInte.getServerFormat())
end

function gmInte.serverStart()
    gmInte.http.post("/servers/:serverID/start", gmInte.getServerFormat())
end

function gmInte.serverShutDown()
    gmInte.http.post("/servers/:serverID/stop")
end

timer.Create("gmInte.sendStatus", 300, 0, function() gmInte.sendStatus() end)
hook.Add("Initialize", "gmInte:Server:Initialize:SendStatus", function() timer.Simple(1, function() gmInte.serverStart() end) end)
hook.Add("ShutDown", "gmInte:Server:ShutDown:SendStatus", function() gmInte.serverShutDown() end)