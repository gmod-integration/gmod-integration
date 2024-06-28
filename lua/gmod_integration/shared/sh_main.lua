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

// Is Private IP
function gmInte.isPrivateIP(ip)
    // detect localhost
    if (ip == "localhost") then return true end
    // detect private IP addresses (RFC 1918)
    local parts = string.Explode(".", ip)
    if (parts[1] == "192" && parts[2] == "168") then return true end
    if (parts[1] == "10") then return true end
    if (parts[1] == "172" && tonumber(parts[2]) >= 16 && tonumber(parts[2]) <= 31) then return true end
    if (parts[1] == "127") then return true end
    return false
end