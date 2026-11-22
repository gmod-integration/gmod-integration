// Is Private IP
function gmInte.isPrivateIP(ip)
    if !isstring(ip) then return false end
    if ip == "localhost" then return true end
    if #ip > 15 then return false end
    local first, second, third, fourth = string.match(ip, "^(%d+)%.(%d+)%.(%d+)%.(%d+)$")
    if !fourth then return false end
    local parts = { first, second, third, fourth }
    for index, part in ipairs(parts) do
        -- A hostname or ambiguous numeric form must never select a plaintext transport.
        if (#part > 1 && string.sub(part, 1, 1) == "0") || tonumber(part) > 255 then return false end
        parts[index] = tonumber(part)
    end
    return parts[1] == 10 || parts[1] == 127 || (parts[1] == 192 && parts[2] == 168) ||
        (parts[1] == 172 && parts[2] >= 16 && parts[2] <= 31)
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
