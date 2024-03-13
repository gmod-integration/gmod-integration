//
// Websocket
//

function gmInte.wsRcon(data)
    gmInte.log("Rcon Command from Discord '" .. data.command .. "' by " .. data.steamID)
    game.ConsoleCommand(data.command .. "\n")
end