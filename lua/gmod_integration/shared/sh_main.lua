//
// Functions
//

// Log
function gmInte.log(msg, debug)
    if (debug && !gmInte.config.debug) then return end
	print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [Gmod Integration] " .. msg)
end

// Log Error
function gmInte.logError(msg, debug)
    if (debug && !gmInte.config.debug) then return end
    print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [Gmod Integration] [ERROR] " .. msg)
end

// Log Warning
function gmInte.logWarning(msg, debug)
    if (debug && !gmInte.config.debug) then return end
    print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [Gmod Integration] [WARNING] " .. msg)
end

// Log Hint
function gmInte.logHint(msg, debug)
    if (debug && !gmInte.config.debug) then return end
    print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [Gmod Integration] [HINT] " .. msg)
end