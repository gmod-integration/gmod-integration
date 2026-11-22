-- Scan untrusted text before the engine JSON parser can allocate nested tables.
function gmInte.decodeBoundedNetJSON(json, maximumBytes)
    if not isstring(json) or #json == 0 or #json > (maximumBytes or 60000) then return end
    local depth, quoted, escaped = 0, false, false
    for index = 1, #json do
        local char = json:sub(index, index)
        if quoted then
            if escaped then escaped = false
            elseif char == "\\" then escaped = true
            elseif char == '"' then quoted = false end
        elseif char == '"' then quoted = true
        elseif char == "{" or char == "[" then
            depth = depth + 1
            if depth > 24 then return end
        elseif char == "}" or char == "]" then
            depth = depth - 1
            if depth < 0 then return end
        end
    end
    if depth ~= 0 or quoted then return end
    local ok, value = pcall(util.JSONToTable, json)
    if ok and istable(value) then return value end
end
