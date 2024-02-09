//
// Methods
//

local function getServerFormat()
    return {
        ["hostname"] = GetHostName(),
        ["ip"] = game.GetIPAddress(),
        ["port"] = GetConVar("hostport"):GetInt(),
        ["map"] = game.GetMap(),
        ["players"] = #player.GetAll(),
        ["maxplayers"] = game.MaxPlayers(),
        ["gamemode"] = engine.ActiveGamemode(),
        ["uptime"] = math.Round(RealTime() / 60)
    }
end

function gmInte.sendStatus()
    gmInte.http.post("/status", getServerFormat())
end

-- function gmInte.serverStart()
--     gmInte.http.post("/start", getServerFormat())
-- end

function gmInte.serverShutDown()
    gmInte.http.post("/shutdown")
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