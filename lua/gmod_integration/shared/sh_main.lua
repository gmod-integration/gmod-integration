// Functions
function gmInte.log(msg, debug)
    if (debug && !gmInte.config.debug) then return end
    //format: [2021-08-01 00:00:00] [INFO] msg
	print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [Garry's Mod Integration] " .. msg)
end