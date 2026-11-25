local MAX_MESSAGE_BYTES = 32 * 1024
local MAX_BUFFER_BYTES = 64 * 1024
local MAX_BUFFER_MESSAGES = 64
local MAX_MESSAGES_PER_SECOND = 10
local MAX_BYTES_PER_SECOND = 64 * 1024
local queue, bufferedBytes = {}, 0
local deadline
local windowStart, windowMessages, windowBytes = 0, 0, 0
local capturing, forwarding = false, false

function gmInte.stopConsoleStream()
    deadline = nil
    queue, bufferedBytes = {}, 0
    windowStart, windowMessages, windowBytes = SysTime(), 0, 0
    gmInte.config.consoleLiveExporter = false
    gmInte.enableConsoleLiveExporter = false
end

function gmInte.validateConsoleStream(data)
    if !istable(data) || data.method != "wsConsoleStream" || !isbool(data.enabled) || !isnumber(data.expiresAt) then return false end
    for key in pairs(data) do
        if key != "method" && key != "enabled" && key != "expiresAt" then return false end
    end
    if data.expiresAt != data.expiresAt || data.expiresAt % 1 != 0 then return false end
    if !data.enabled then return data.expiresAt == 0 end
    local remaining = data.expiresAt - os.time() * 1000
    -- Permit small clock skew; the actual monotonic lease can never exceed 30 seconds.
    return remaining > 0 && remaining <= 35 * 1000
end

local function connected()
    return gmInte.aprovedCredentials && gmInte.websocket && gmInte.websocket:isConnected()
end

function gmInte.wsConsoleStream(data)
    if !gmInte.validateConsoleStream(data) then return false end
    if !data.enabled then gmInte.stopConsoleStream() return true end
    if !connected() then gmInte.stopConsoleStream() return false end
    deadline = SysTime() + math.min(30, (data.expiresAt - os.time() * 1000) / 1000)
    gmInte.config.consoleLiveExporter = true
    gmInte.enableConsoleLiveExporter = true
    return true
end

local function active()
    if !deadline then
        if gmInte.config.consoleLiveExporter || gmInte.enableConsoleLiveExporter then gmInte.stopConsoleStream() end
        return false
    end
    if SysTime() >= deadline || !connected() || gmInte.config.consoleLiveExporter != true || gmInte.enableConsoleLiveExporter != true then
        gmInte.stopConsoleStream()
        return false
    end
    return true
end

local function serialize(value)
    local kind = type(value)
    if kind == "table" then return "<table>" end
    if kind == "function" || kind == "thread" || kind == "userdata" then return "<" .. kind .. ">" end
    return tostring(value)
end

local function capture(separator, newline, skipColors, ...)
    if capturing || forwarding || !active() || #queue >= MAX_BUFFER_MESSAGES || bufferedBytes >= MAX_BUFFER_BYTES then return end
    capturing = true
    -- Native output still runs even when a value cannot be serialized. Tables are never traversed.
    pcall(function(...)
        local parts, bytes = {}, 0
        for index = 1, math.min(select("#", ...), 64) do
            local value = select(index, ...)
            if !(skipColors && isfunction(IsColor) && IsColor(value)) then
                local part = string.gsub(string.sub(serialize(value), 1, MAX_MESSAGE_BYTES), "\0", "")
                local prefix = #parts > 0 && separator || ""
                local remaining = MAX_MESSAGE_BYTES - bytes - #prefix - (newline && 1 || 0)
                if remaining <= 0 then break end
                part = string.sub(part, 1, remaining)
                parts[#parts + 1] = prefix .. part
                bytes = bytes + #prefix + #part
            end
        end
        local text = table.concat(parts) .. (newline && "\n" || "")
        if #text == 0 || #queue >= MAX_BUFFER_MESSAGES || bufferedBytes + #text > MAX_BUFFER_BYTES then return end
        queue[#queue + 1] = text
        bufferedBytes = bufferedBytes + #text
    end, ...)
    capturing = false
end

-- Retain the native functions across Lua auto-refresh, so wrappers never accumulate.
gmInte.consoleStreamOriginals = gmInte.consoleStreamOriginals || { print = print, Msg = Msg, MsgN = MsgN, MsgC = MsgC }
local originals = gmInte.consoleStreamOriginals
for name, options in pairs({ print = { "\t", true }, Msg = { "", false }, MsgN = { "", true }, MsgC = { "", false, true } }) do
    local original = originals[name]
    if isfunction(original) then
        _G[name] = function(...)
            capture(options[1], options[2], options[3], ...)
            return original(...)
        end
    end
end

gmInte.stopConsoleStream()
timer.Create("gmInte:ConsoleStream:Flush", 0.1, 0, function()
    if !active() then return end
    local now = SysTime()
    if now - windowStart >= 1 then windowStart, windowMessages, windowBytes = now, 0, 0 end
    while #queue > 0 && windowMessages < MAX_MESSAGES_PER_SECOND && windowBytes + #queue[1] <= MAX_BYTES_PER_SECOND do
        local text = table.remove(queue, 1)
        bufferedBytes = bufferedBytes - #text
        windowMessages, windowBytes = windowMessages + 1, windowBytes + #text
        forwarding = true
        local ok, sent = pcall(function() return gmInte.websocket:send("console_live_exporter", { data = text }, nil, true) end)
        forwarding = false
        if !ok || sent != true then gmInte.stopConsoleStream() return end
    end
end)
