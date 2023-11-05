//
// Functions
//

// Log
function gmInte.log(msg, debug)
    if (debug && !gmInte.debug) then return end
	print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [Gmod Integration] " .. msg)
end

// Log Error
function gmInte.logError(msg, debug)
    if (debug && !gmInte.debug) then return end
    print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [Gmod Integration] [ERROR] " .. msg)
    if (debug) then print(debug.traceback()) end
end

// Log Warning
function gmInte.logWarning(msg, debug)
    if (debug && !gmInte.debug) then return end
    print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [Gmod Integration] [WARNING] " .. msg)
    if (debug) then print(debug.traceback()) end
end

// Log Hint
function gmInte.logHint(msg, debug)
    if (debug && !gmInte.debug) then return end
    print("[" .. os.date("%Y-%m-%d %H:%M:%S") .. "] [Gmod Integration] [HINT] " .. msg)
    if (debug) then print(debug.traceback()) end
end