// Functions
function gmInte.log(msg, debug)
    if (debug && !gmInte.config.debug) then return end
    //format: [2021-08-01 00:00:00] [INFO] msg
	print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [Garry's Mod Integration] " .. msg)
end

// Chat Command
local trigger = {
    "link",
    "gmint",
    "gminte"
}

hook.Add("OnPlayerChat", "gm_inte:con-chat", function(ply, strText, bTeam, bDead)
    if (ply != LocalPlayer() ) then return end

	strText = string.sub(string.lower(strText ), 2)
    if (table.HasValue(trigger, strText)) then
        gui.OpenURL("https://vetif.gmod-integration.com")
		return true
	end
end)