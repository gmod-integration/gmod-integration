//
// Websocket
//

function gmInte.wsSyncName(data)
    local ply = player.GetBySteamID(data.player.steamID64)
    if not IsValid(ply) then return end
    ply:SetName(data.newName)
end

//
// Methods
//

function gmInte.playerChangeName(ply, oldName, newName)
    if (!gmInte.plyValid(ply)) then return end

    gmInte.http.post("/players/" .. ply:SteamID64() .. "/name",
        {
            ["player"] = gmInte.playerFormat(ply),
            ["oldName"] = oldName,
            ["newName"] = newName,
        }
    )
end

//
// Hooks
//

hook.Add("onPlayerChangedName", "gmInte:PlayerChangeName", function(ply, old, new)
    gmInte.playerChangeName(ply, old, new)
end)