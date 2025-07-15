local oldPrint = print

local function serialize(val)
    local ok, result = pcall(function()
        local t = type(val)
        if t == "string" or t == "number" then
            return tostring(val)
        elseif t == "Vector" or t == "Angle" then
            return tostring(val)
        elseif t == "Entity" then
            return IsValid(val) and "Entity[" .. val:EntIndex() .. "]" or "Entity[NULL]"
        elseif t == "table" then
            local parts = {}
            for k, v in pairs(val) do
                parts[#parts+1] = "[" .. serialize(k) .. "]=" .. serialize(v)
            end
            return "{ " .. table.concat(parts, ", ") .. " }"
        else
            return "<" .. t .. ">"
        end
    end)
    if ok then
        return result
    else
        return "<serialization error>"
    end
end

function print(...)
    if gmInte.enableConsoleLiveExporter then
        local parts = {}
        for i = 1, select("#", ...) do
            parts[i] = serialize(select(i, ...))
        end

        local msg = table.concat(parts, " ")
        local ok, err = pcall(function()
            gmInte.websocket:send("console_live_exporter", { data = msg }, nil, true)
        end)
        if not ok then
            oldPrint("ConsoleLiveExporter send error:", err)
        end
    end

    oldPrint(...)
end
