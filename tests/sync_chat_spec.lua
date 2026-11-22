local passes, failures = 0, {}
local now, requests, warnings, sent, hooks, players
local privateMessage = "fixture-private-chat-text"

local function reset()
    now, requests, warnings, sent, hooks = 0, {}, {}, {}, {}
    SERVER, CLIENT, SAM_LOADED, sam = true, false, false, nil
    isstring = function(value) return type(value) == "string" end
    isnumber = function(value) return type(value) == "number" end
    isfunction = function(value) return type(value) == "function" end
    IsValid = function(value) return value && value.valid == true end
    CurTime = function() return now end
    Color = function(r, g, b) return { r = r, g = g, b = b } end
    local function player(admin, valid)
        return {
            valid = valid,
            IsPlayer = function() return true end,
            gmIntIsAdmin = function() return admin end,
            SteamID64 = function() return "76561198012345678" end,
        }
    end
    players = { player(false, true), player(true, true), player(true, false) }
    _G.player = { GetAll = function() return players end }
    hook = { Add = function(event, _, callback) hooks[event] = callback end }
    timer = { Simple = function(_, callback) callback() end }
    gmInte = {
        api = { post = function(endpoint, body, success, failed)
            requests[#requests + 1] = { endpoint = endpoint, body = body, success = success, failed = failed }
            return true
        end },
        getPlayerFormat = function(ply) return { steamID64 = ply:SteamID64() } end,
        getTranslation = function(_, fallback) return fallback end,
        logWarning = function(message) warnings[#warnings + 1] = message end,
        SendNet = function(id, body, ply) sent[#sent + 1] = { id = id, body = body, ply = ply } end,
    }
    loadGLua("lua/gmod_integration/modules/sync_chat/sv_sync_chat.lua")
end

local function test(name, callback)
    local ok, message = pcall(callback)
    if ok then passes = passes + 1
    else failures[#failures + 1] = name .. ": " .. tostring(message) end
end

test("ordinary chat retains its payload and does not suppress the local game message", function()
    reset()
    assert(hooks.PlayerSay(players[1], privateMessage, false) == nil)
    assert(#requests == 1)
    assert(requests[1].endpoint == "/servers/:serverID/players/76561198012345678/say")
    assert(requests[1].body.text == privateMessage and requests[1].body.teamOnly == false)
    assert(type(requests[1].failed) == "function" and #warnings == 0 and #sent == 0)
end)

test("a failed relay emits a fixed console diagnostic and privately warns only valid administrators", function()
    reset()
    gmInte.playerSay(players[1], privateMessage, true)
    requests[1].failed(502, { error = "fixture-private-credential", content = privateMessage })
    assert(#warnings == 1 and warnings[1]:find("could not confirm delivery", 1, true))
    assert(warnings[1]:find("(502)", 1, true))
    assert(not warnings[1]:find(privateMessage, 1, true) and not warnings[1]:find("fixture-private-credential", 1, true))
    assert(#sent == 1 and sent[1].id == "chatColorMessage" and sent[1].ply == players[2])
    assert(sent[1].body[1].text:find("relay configuration", 1, true))
    assert(not sent[1].body[1].text:find(privateMessage, 1, true))
end)

test("repeated failures across players cannot spam diagnostics or expose nonnumeric error details", function()
    reset()
    gmInte.playerSay(players[1], privateMessage, false)
    requests[1].failed(503)
    gmInte.playerSay(players[2], privateMessage, false)
    requests[2].failed(502)
    now = 59
    requests[2].failed(504)
    assert(#warnings == 1 and #sent == 1)
    now = 60
    requests[2].failed(504)
    assert(#warnings == 2 and #sent == 2)
    now = 120
    requests[2].failed("fixture-private-error")
    assert(#warnings == 3 and not warnings[3]:find("fixture-private-error", 1, true))
end)

if #failures > 0 then error(table.concat(failures, "\n")) end
print("sync_chat_spec: " .. passes .. " checks passed")
