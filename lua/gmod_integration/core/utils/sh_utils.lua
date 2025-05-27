local function getTimeStamp()
    if !gmInte.config.debug then return "" end
    return " | " .. os.date(gmInte.config.logTimestamp || "%Y-%m-%d %H:%M:%S")
end

function gmInte.log(msg, debug)
    if debug && !gmInte.config.debug then return end
    print(getTimeStamp() .. " | Gmod Integration | " .. msg)
end

// Log Error
function gmInte.logError(msg, debug)
    if debug && !gmInte.config.debug then return end
    print(getTimeStamp() .. " | Gmod Integration | ERROR | " .. msg)
end

// Log Warning
function gmInte.logWarning(msg, debug)
    if debug && !gmInte.config.debug then return end
    print(getTimeStamp() .. " | Gmod Integration | WARNING | " .. msg)
end

// Log Hint
function gmInte.logHint(msg, debug)
    if debug && !gmInte.config.debug then return end
    print(getTimeStamp() .. " | Gmod Integration | HINT | " .. msg)
end

// Is Private IP
function gmInte.isPrivateIP(ip)
    // detect localhost
    if ip == "localhost" then return true end
    // detect private IP addresses (RFC 1918)
    local parts = string.Explode(".", ip)
    if parts[1] == "192" && parts[2] == "168" then return true end
    if parts[1] == "10" then return true end
    if parts[1] == "172" && tonumber(parts[2]) >= 16 && tonumber(parts[2]) <= 31 then return true end
    if parts[1] == "127" then return true end
    return false
end

// Generate Random String
function gmInte.generateRandomString(length)
    local charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
    local result = ""
    math.randomseed(os.time() + #charset * math.random(1, 100))
    for i = 1, length do
        local randomIndex = math.random(1, #charset)
        result = result .. string.sub(charset, randomIndex, randomIndex)
    end
    return result
end

// Generate Random UUIDV4
function gmInte.generateUUIDV4()
    local uuid = string.format("%s-%s-%s-%s-%s", gmInte.generateRandomString(8), gmInte.generateRandomString(4), "4" .. gmInte.generateRandomString(3), gmInte.generateRandomString(4), gmInte.generateRandomString(12))
    return uuid
end