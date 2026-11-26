local requests, logs
local passes, failures = 0, {}

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

local function reset()
    requests, logs = {}, {}
    istable = function(value) return type(value) == "table" end
    table.Copy = copy
    AWarn = nil
    gmInte = {
        api = { post = function(endpoint, body, success, failed)
            requests[#requests + 1] = { endpoint = endpoint, body = body, success = success, failed = failed }
        end },
        log = function(message) logs[#logs + 1] = message end,
        logError = function(message) logs[#logs + 1] = message end,
    }
    loadGLua("lua/gmod_integration/modules/sync_warns/awarn3/sv_sync_warn.lua")
end

local function warnings(count)
    local result = {}
    for index = 1, count do
        result[index] = { playerSteamID64 = "76561198012345678", adminSteamID64 = "76561198012345679", date = index, reason = "Private reason " .. index }
    end
    return result
end

local function test(name, callback)
    local ok, error = pcall(callback)
    if ok then passes = passes + 1
    else failures[#failures + 1] = name .. ": " .. tostring(error) end
end

test("warning exports send ordered batches only after acknowledgement", function()
    reset()
    assert(gmInte.serverExportWarns(warnings(1201)))
    assert(#requests == 1 and #requests[1].body.warns == 500)
    assert(requests[1].body.warns[1].date == 1 and requests[1].body.warns[500].date == 500)
    requests[1].success(200, {})
    assert(#requests == 2 and #requests[2].body.warns == 500)
    assert(requests[2].body.warns[1].date == 501 and requests[2].body.warns[500].date == 1000)
    requests[2].success(200, {})
    assert(#requests == 3 and #requests[3].body.warns == 201)
    assert(requests[3].body.warns[1].date == 1001 and requests[3].body.warns[201].date == 1201)
    requests[3].success(200, {})
    assert(#requests == 3 and logs[1]:find("completed", 1, true))
end)

test("an active export blocks duplicates and holds an immutable snapshot", function()
    reset()
    local source = warnings(501)
    assert(gmInte.serverExportWarns(source))
    assert(gmInte.serverExportWarns(source) == false and #requests == 1)
    source[501].reason = "changed during export"
    source[502] = source[501]
    requests[1].success(200, {})
    assert(#requests == 2 and #requests[2].body.warns == 1)
    assert(requests[2].body.warns[1].reason == "Private reason 501")
end)

test("uncertain delivery stops immediately and permits an explicit retry", function()
    reset()
    local source = warnings(1001)
    gmInte.serverExportWarns(source)
    requests[1].success(200, {})
    assert(#requests == 2)
    requests[2].failed(504, { error = "delivery_uncertain" })
    assert(#requests == 2, "A failed mutation must not replay itself or send the next batch")
    assert(logs[1]:find("batch 2", 1, true) and logs[1]:find("504", 1, true))
    assert(not logs[1]:find("Private reason", 1, true))
    assert(gmInte.serverExportWarns(source) and #requests == 3)
    assert(requests[3].body.warns[1].date == 1)
end)

test("empty input stays inert and completed exports can run again", function()
    reset()
    assert(gmInte.serverExportWarns({}) == false and gmInte.serverExportWarns(nil) == false)
    assert(#requests == 0)
    assert(gmInte.serverExportWarns(warnings(1)))
    requests[1].success(200, {})
    assert(gmInte.serverExportWarns(warnings(1)) and #requests == 2)
end)

if #failures > 0 then error(table.concat(failures, "\n")) end
print("Module transport regressions: " .. passes .. " passed")
