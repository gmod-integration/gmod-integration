local passes, failures = 0, {}
local now, requests, hooks, timers, players, rows, warnings, messages, effects, failSQL, countOverride, compilations
local STEAM, OTHER = "76561198012345678", "76561198012345679"
local GRANT = "6cbe4319-4441-4ce6-a81c-b9c8ea7efc27"
local TOKEN = "bbacfe57-2078-4cf2-8744-e982bc663e5a"
local ACTION = "5e8a19ba-d201-4741-82cb-4e4cf7555eaf"
local realTime = os.time
local module = "lua/gmod_integration/modules/rewards/sv_rewards.lua"

local function copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = copy(child) end
    return result
end

local function fields(statement)
    local values, position = {}, 1
    while position <= #statement do
        local start = statement:find("'", position, true)
        if not start then break end
        local value, index = "", start + 1
        while index <= #statement do
            local char = statement:sub(index, index)
            if char == "'" then
                if statement:sub(index + 1, index + 1) == "'" then value = value .. "'"; index = index + 2
                else break end
            else value = value .. char; index = index + 1 end
        end
        values[#values + 1] = value
        position = index + 1
    end
    return values
end

local function player(id, bot)
    return {
        valid = true, id = id, bot = bot, money = 100, PS_Points = 50, PS2_Wallet = { points = 25 },
        SteamID64 = function(self) return self.id end,
        IsPlayer = function() return true end,
        IsBot = function(self) return self.bot == true end,
        getDarkRPVar = function(self) return self.money end,
        addMoney = function(self, amount) self.money = self.money + amount; effects[#effects + 1] = "darkrp" end,
        PS_GivePoints = function(self, amount) self.PS_Points = self.PS_Points + amount; effects[#effects + 1] = "pointshop" end,
        PS2_AddStandardPoints = function(self, amount) self.PS2_Wallet.points = self.PS2_Wallet.points + amount; effects[#effects + 1] = "pointshop2" end,
        ChatPrint = function(_, message) messages[#messages + 1] = message end,
    }
end

local function reset()
    now, requests, hooks, timers, rows, warnings, messages, effects = 1700000000, {}, {}, {}, {}, {}, {}, {}
    failSQL, countOverride = nil, nil
    compilations = {}
    SERVER, CLIENT, DarkRP, PS, Pointshop2 = true, false, {}, {}, {}
    isstring = function(value) return type(value) == "string" end
    istable = function(value) return type(value) == "table" end
    isnumber = function(value) return type(value) == "number" end
    isfunction = function(value) return type(value) == "function" end
    IsValid = function(value) return type(value) == "table" and value.valid == true end
    SysTime = function() return now end
    os.time = function() return now end
    local sourceHashes, sourceCount = {}, 0
    util = { SHA256 = function(source)
        if not sourceHashes[source] then
            sourceCount = sourceCount + 1
            sourceHashes[source] = string.format("%064x", sourceCount)
        end
        return sourceHashes[source]
    end }
    CompileString = function(source, identifier, handleError)
        assert(handleError == false, "Compilation must not expose engine error details")
        compilations[#compilations + 1] = { source = source, identifier = identifier }
        local compiled, message = (loadstring or load)(source, "@" .. identifier)
        if not compiled then return message end
        return function(ply, reward)
            local saved = rows[gmInte.config.id .. "/" .. reward.id .. "/" .. reward.actionID]
            assert(saved and saved.status == "started", "Lua must not execute before its durable journal reservation")
            return compiled(ply, reward)
        end
    end
    players = { player(STEAM), player(OTHER, true) }
    FindMetaTable = function() return players[1] end
    _G.player = {
        GetAll = function() return players end,
        GetBySteamID64 = function(id)
            for _, ply in ipairs(players) do if ply.id == id and ply.valid then return ply end end
        end,
    }
    hook = { Add = function(event, id, callback)
        hooks[event] = hooks[event] or {}; hooks[event][id] = callback
    end }
    timer = { Create = function(id, _, _, callback) timers[id] = callback end, Simple = function(_, callback) timers.simple = callback end }
    sql = {
        SQLStr = function(value) return "'" .. value:gsub("'", "''") .. "'" end,
        Query = function(statement)
            if failSQL and failSQL(statement) then return false end
            local values = fields(statement)
            if statement:match("^CREATE ") then return nil end
            if statement:match("^DELETE ") then
                local before = tonumber(statement:match("expires_at < (%d+)$"))
                for key, row in pairs(rows) do if row.expires_at < before then rows[key] = nil end end
                return nil
            end
            if statement:match("^SELECT COUNT") then
                local count = 0; for _ in pairs(rows) do count = count + 1 end
                return { { total = tostring(countOverride or count) } }
            end
            if statement:match("^SELECT fingerprint") then return rows[values[1]] and { copy(rows[values[1]]) } or nil end
            if statement:match("^INSERT INTO") then
                assert(not rows[values[1]], "Journal insert must not overwrite an existing action")
                rows[values[1]] = { fingerprint = values[2], status = values[3], reason = values[4], expires_at = tonumber(statement:match(", (%d+)%)$")) }
                return nil
            end
            if statement:match("^UPDATE ") then
                local row = rows[values[3]]
                if row and row.status == "started" then row.status, row.reason = values[1], values[2] end
                return nil
            end
            error("Unexpected SQL statement")
        end,
    }
    gmInte = {
        config = { id = "server-one", token = "fixture-private-token", websocketFQDN = "fixture.invalid" },
        aprovedCredentials = true, websocket = {},
        api = { post = function(endpoint, body, success, failed)
            requests[#requests + 1] = { endpoint = endpoint, body = copy(body), success = success, failed = failed }
            return true
        end },
        logWarning = function(message) warnings[#warnings + 1] = message end,
        getTranslation = function(_, fallback, title) return fallback:gsub("{1}", function() return title end) end,
    }
    loadGLua(module)
end

local function delivery(actionType, amount)
    return { id = GRANT, token = TOKEN, steamID64 = STEAM, ruleName = "Welcome reward", expiresAt = now + 7 * 86400,
        actions = { { id = ACTION, type = actionType or "darkrp_money", amount = amount or 500 } } }
end

local function luaDelivery(code)
    local value = delivery()
    value.actions = { { id = ACTION, type = "lua", code = code or "ply.luaCalls = (ply.luaCalls or 0) + 1" } }
    return value
end

local function poll()
    timers["gmInte:Rewards:Poll"]()
    return requests[#requests]
end

local function respond(value)
    local request = poll()
    assert(request.endpoint == "/servers/:serverID/rewards/poll")
    request.success(200, { deliveries = { value } })
    return requests[#requests]
end

local function test(name, callback)
    local ok, message = pcall(callback)
    if ok then passes = passes + 1 else failures[#failures + 1] = name .. ": " .. tostring(message) end
end

test("polls only authenticated server connections and sends human identities with detected integrations", function()
    reset()
    gmInte.aprovedCredentials = false; timers["gmInte:Rewards:Poll"](); assert(#requests == 0)
    gmInte.aprovedCredentials = true; gmInte.config.id = ""; timers["gmInte:Rewards:Poll"](); assert(#requests == 0)
    gmInte.config.id = "server-one"
    local request = poll()
    assert(#request.body.players == 1 and request.body.players[1] == STEAM)
    assert(request.body.integrations.darkrp and request.body.integrations.pointshop and request.body.integrations.pointshop2)
    assert(request.body.token == nil)
    timers["gmInte:Rewards:Poll"](); assert(#requests == 1, "Concurrent polls must be bounded")
end)

test("credits each supported fixed integration and confirms immutable individual action results", function()
    reset()
    local value = delivery()
    value.actions[2] = { id = "96c949d4-92a8-4674-a762-8d4ce1feb379", type = "pointshop_points", amount = 200 }
    value.actions[3] = { id = "ba2fd4fd-3e94-4d57-a2fc-984e04cbdac1", type = "pointshop2_points", amount = 300 }
    local ack = respond(value)
    assert(#effects == 3 and players[1].money == 600 and players[1].PS_Points == 250 and players[1].PS2_Wallet.points == 325)
    assert(ack.endpoint == "/servers/:serverID/rewards/ack" and ack.body.id == GRANT and ack.body.token == TOKEN)
    assert(#ack.body.results == 3)
    for _, result in ipairs(ack.body.results) do assert(result.status == "delivered" and result.reason == nil) end
    assert(#messages == 1 and messages[1] == "Reward received: Welcome reward")
end)

test("polls at most64 humans while rotating batches so larger servers do not starve players", function()
    reset()
    players = {}
    for index = 1, 100 do players[index] = player("76561198012345" .. string.format("%03d", index)) end
    local first = poll()
    assert(#first.body.players == 64 and first.body.players[1] == players[1].id)
    first.success(200, { deliveries = {} })
    local second = poll()
    assert(#second.body.players == 64 and second.body.players[1] == players[65].id)
end)

test("accepts valid long localized rule titles while keeping control characters forbidden", function()
    for _, character in ipairs({ "é", "奖" }) do
        reset()
        local value = delivery()
        value.ruleName = string.rep(character, 80)
        assert(respond(value).body.results[1].status == "delivered" and #effects == 1)
        assert(messages[1] == "Reward received: " .. value.ruleName)
    end
    reset()
    local value = delivery()
    value.ruleName = "Récompense\0privée"
    respond(value)
    assert(#effects == 0 and #requests == 1)
end)

test("duplicate deliveries after lost acknowledgement, token rotation and module reload never credit twice", function()
    reset()
    local value = delivery()
    respond(value).failed(504, { error = "private-error" })
    assert(respond(value).body.results[1].status == "delivered" and #effects == 1)
    gmInte.config.token = "rotated-private-token"
    loadGLua(module)
    assert(respond(value).body.results[1].status == "delivered" and #effects == 1 and #messages == 1)
    for _, message in ipairs(warnings) do assert(not message:find("private", 1, true)) end
end)

test("an interrupted journal remains uncertain after restart and never retries a potentially applied credit", function()
    reset()
    local value = delivery()
    failSQL = function(statement) return statement:match("^UPDATE ") end
    local ack = respond(value)
    assert(#effects == 1 and ack.body.results[1].status == "uncertain")
    failSQL = nil
    loadGLua(module)
    assert(respond(value).body.results[1].status == "uncertain" and #effects == 1)
end)

test("an integration exception after a partial side effect is uncertain and cannot duplicate the partial credit", function()
    reset()
    players[1].addMoney = function(self, amount) self.money = self.money + amount; effects[#effects + 1] = "partial"; error("private-addon-error") end
    local value = delivery()
    assert(respond(value).body.results[1].status == "uncertain" and players[1].money == 600)
    assert(respond(value).body.results[1].status == "uncertain" and #effects == 1)
end)

test("a missing integration defers without reserving an action and can recover later", function()
    reset()
    local value = delivery("pointshop2_points")
    local request = poll()
    Pointshop2 = nil
    request.success(200, { deliveries = { value } })
    assert(requests[#requests].body.results[1].status == "pending" and next(rows) == nil and #effects == 0)
    Pointshop2 = {}
    assert(respond(value).body.results[1].status == "delivered" and #effects == 1)
end)

test("a player going offline between poll and response defers without consuming the reward", function()
    reset()
    local value, request = delivery(), poll()
    players[1].valid = false
    request.success(200, { deliveries = { value } })
    assert(requests[#requests].body.results[1].reason == "player_offline" and next(rows) == nil)
    players[1] = player(STEAM)
    assert(respond(value).body.results[1].status == "delivered" and #effects == 1)
end)

test("newly joined player wallets receive an initialization grace period", function()
    reset()
    local value = delivery()
    hooks.PlayerInitialSpawn["gmInte:Rewards:PlayerReady"](players[1])
    assert(respond(value).body.results[1].status == "pending" and next(rows) == nil)
    now = now + 10
    assert(respond(value).body.results[1].status == "delivered")
end)

test("validates the whole response before any credit, including unexpected fields and duplicate action IDs", function()
    local mutations = {
        function(value) value.actions[2] = { id = ACTION, type = "pointshop_points", amount = 1 } end,
        function(value) value.actions[2] = { id = "96c949d4-92a8-4674-a762-8d4ce1feb379", type = "lua", amount = 1 } end,
        function(value) value.actions[1].command = "arbitrary-command" end,
        function(value) value.steamID64 = OTHER end,
        function(value) value.token = "../../private" end,
        function(value) value.ruleName = "bad\nname" end,
        function(value) value.expiresAt = now - 1 end,
        function(value) value.expiresAt = now + 32 * 86400 end,
        function(value) value.actions[1].amount = 0 end,
        function(value) value.actions[1].amount = 1000001 end,
        function(value) value.actions[1].amount = 1.5 end,
        function(value) value.actions[1].amount = 0 / 0 end,
        function(value) value.actions[1].amount = math.huge end,
        function(value) value.actions.extra = value.actions[1] end,
        function(value) value.actions = {} end,
        function(value) value.extra = "private" end,
    }
    for _, mutate in ipairs(mutations) do
        reset()
        local value = delivery(); mutate(value)
        respond(value)
        assert(#effects == 0 and #requests == 1 and next(rows) == nil)
    end
    reset()
    local request = poll()
    request.success(200, { deliveries = { delivery() }, extra = "private" })
    assert(#requests == 1 and #effects == 0)
end)

test("rejects oversized batches and arrays with gaps without accepting an initial valid prefix", function()
    reset()
    local batch = {}; for index = 1, 11 do batch[index] = delivery() end
    poll().success(200, { deliveries = batch })
    assert(#effects == 0 and #requests == 1)
    local value = delivery()
    value.actions[3] = value.actions[1]
    respond(value)
    assert(#effects == 0)
end)

test("credential changes, replacement sockets and generation changes discard late responses", function()
    for _, change in ipairs({
        function() gmInte.config.token = "other" end,
        function() gmInte.config.id = "another-server" end,
        function() gmInte.websocket = {} end,
        function() gmInte.config.websocketFQDN = "other.invalid" end,
        function() hooks["GmodIntegration:Websocket:Restart"]["gmInte:Rewards:Restart"]() end,
        function() hooks.ShutDown["gmInte:Rewards:Shutdown"]() end,
    }) do
        reset()
        local value, request = delivery(), poll()
        change(); request.success(200, { deliveries = { value } })
        assert(#effects == 0 and #requests == 1 and next(rows) == nil)
    end
end)

test("changed contents on a previously seen grant cannot reuse its action identity", function()
    reset()
    local value = delivery()
    respond(value)
    value.actions[1].amount = 900
    assert(respond(value).body.results[1].status == "uncertain" and players[1].money == 600 and #effects == 1)
end)

test("journal failures before execution and a saturated journal always fail closed", function()
    for _, matcher in ipairs({ "^CREATE ", "^SELECT fingerprint", "^INSERT INTO", "^SELECT COUNT", "^DELETE " }) do
        reset()
        failSQL = function(statement) return statement:match(matcher) end
        local ack = respond(delivery())
        assert(ack.body.results[1].status == "pending" and ack.body.results[1].reason == "journal_unavailable" and #effects == 0)
    end
    reset(); countOverride = 100000
    assert(respond(delivery()).body.results[1].reason == "journal_unavailable" and #effects == 0)
end)

test("expired journal rows are pruned after the extra retention day while active uncertain rows remain", function()
    reset()
    rows.expired = { expires_at = now - 86401, status = "started" }
    rows.active = { expires_at = now + 86400, status = "uncertain" }
    respond(delivery())
    assert(rows.expired == nil and rows.active.status == "uncertain")
end)

test("storage is namespaced by server rather than credentials and never exposes credentials to players", function()
    reset()
    local value = delivery()
    respond(value)
    local key, row = next(rows)
    assert(key == "server-one/" .. GRANT .. "/" .. ACTION)
    assert(not key:find("private", 1, true) and not row.fingerprint:find("private", 1, true))
    for _, text in ipairs(messages) do assert(not text:find(TOKEN, 1, true) and not text:find("private", 1, true)) end
end)

test("executes server Lua with bound recipient and reward variables after durable reservation", function()
    reset()
    local value = luaDelivery([[
assert(SERVER and not CLIENT)
assert(ply:SteamID64() == steamID64)
ply.luaCalls = (ply.luaCalls or 0) + 1
ply.rewardContext = reward
]])
    local ack = respond(value)
    assert(ack.body.results[1].status == "delivered" and players[1].luaCalls == 1)
    local context = players[1].rewardContext
    assert(context.id == GRANT and context.actionID == ACTION and context.name == value.ruleName and context.steamID64 == STEAM)
    assert(context.token == nil and context.code == nil and #compilations == 1)
    assert(compilations[1].identifier == "GMI Reward " .. ACTION)
    assert(#messages == 1)
end)

test("Lua duplicate delivery and module restart never recompile or execute a successful script twice", function()
    reset()
    local value = luaDelivery()
    respond(value).failed(504, { error = "private-transport-error" })
    assert(respond(value).body.results[1].status == "delivered" and players[1].luaCalls == 1)
    gmInte.config.token = "rotated-private-token"
    loadGLua(module)
    assert(respond(value).body.results[1].status == "delivered" and players[1].luaCalls == 1 and #compilations == 1)
    local _, saved = next(rows)
    assert(not saved.fingerprint:find(value.actions[1].code, 1, true), "Journal must contain a source digest, not script contents")
end)

test("reports Lua syntax failures without starting the action or exposing source and compiler diagnostics", function()
    reset()
    local value = luaDelivery("local private_script_secret = (")
    local ack = respond(value)
    assert(ack.body.results[1].status == "failed" and ack.body.results[1].reason == "lua_compile_failed")
    assert(players[1].luaCalls == nil and next(rows) == nil and #messages == 0)
    for _, message in ipairs(warnings) do assert(not message:find("private", 1, true)) end
    for _, result in ipairs(ack.body.results) do
        for _, part in pairs(result) do assert(type(part) ~= "string" or not part:find("private", 1, true)) end
    end
end)

test("a partial Lua runtime error remains uncertain and cannot replay after reconnect or restart", function()
    reset()
    local value = luaDelivery("ply.luaCalls = (ply.luaCalls or 0) + 1\nerror('private_script_secret')")
    local ack = respond(value)
    assert(ack.body.results[1].status == "uncertain" and ack.body.results[1].reason == "lua_execution_failed")
    assert(players[1].luaCalls == 1 and #messages == 0)
    loadGLua(module)
    assert(respond(value).body.results[1].status == "uncertain" and players[1].luaCalls == 1 and #compilations == 1)
    for _, message in ipairs(warnings) do assert(not message:find("private", 1, true)) end
end)

test("a Lua false return cannot cause a potentially applied script to execute again", function()
    reset()
    local value = luaDelivery("ply.luaCalls = (ply.luaCalls or 0) + 1\nreturn false")
    assert(respond(value).body.results[1].status == "uncertain" and players[1].luaCalls == 1)
    assert(respond(value).body.results[1].status == "uncertain" and players[1].luaCalls == 1)
end)

test("changing source cannot reuse the durable identity of a previously executed Lua action", function()
    reset()
    local value = luaDelivery()
    respond(value)
    value.actions[1].code = "ply.luaCalls = (ply.luaCalls or 0) + 100"
    assert(respond(value).body.results[1].status == "uncertain" and players[1].luaCalls == 1 and #compilations == 1)
end)

test("rejects invalid Lua actions and whole mixed batches before compiling any prefix", function()
    local mutations = {
        function(action) action.code = nil end,
        function(action) action.code = false end,
        function(action) action.code = 1 end,
        function(action) action.code = "" end,
        function(action) action.code = " \n\t " end,
        function(action) action.code = "ply.luaCalls = 1\0" end,
        function(action) action.code = string.rep("x", 65537) end,
        function(action) action.amount = 1 end,
        function(action) action.realm = "client" end,
    }
    for _, mutate in ipairs(mutations) do
        reset()
        local value = luaDelivery(); mutate(value.actions[1])
        value.actions[2] = { id = "96c949d4-92a8-4674-a762-8d4ce1feb379", type = "darkrp_money", amount = 500 }
        respond(value)
        assert(players[1].luaCalls == nil and #effects == 0 and #requests == 1 and #compilations == 0 and next(rows) == nil)
    end
end)

test("unavailable Lua compilation or source hashing defers the action without execution", function()
    for _, missing in ipairs({ "compiler", "hash" }) do
        reset()
        local compiler, hash = CompileString, util.SHA256
        if missing == "compiler" then CompileString = nil else util.SHA256 = nil end
        local value = luaDelivery()
        local ack = respond(value)
        assert(ack.body.results[1].status == "pending" and ack.body.results[1].reason == "lua_unavailable")
        assert(players[1].luaCalls == nil and next(rows) == nil)
        CompileString, util.SHA256 = compiler, hash
        assert(respond(value).body.results[1].status == "delivered" and players[1].luaCalls == 1)
    end
end)

test("journal failures prevent Lua effects and a failed final save remains uncertain after restart", function()
    for _, matcher in ipairs({ "^CREATE ", "^SELECT fingerprint", "^INSERT INTO", "^SELECT COUNT", "^DELETE " }) do
        reset()
        failSQL = function(statement) return statement:match(matcher) end
        local ack = respond(luaDelivery())
        assert(ack.body.results[1].status == "pending" and ack.body.results[1].reason == "journal_unavailable")
        assert(players[1].luaCalls == nil)
    end
    reset()
    local value = luaDelivery()
    failSQL = function(statement) return statement:match("^UPDATE ") end
    assert(respond(value).body.results[1].status == "uncertain" and players[1].luaCalls == 1)
    failSQL = nil
    loadGLua(module)
    assert(respond(value).body.results[1].status == "uncertain" and players[1].luaCalls == 1)
end)

test("stale or expired Lua deliveries cannot compile or execute", function()
    for _, change in ipairs({
        function() gmInte.config.token = "changed" end,
        function() gmInte.websocket = {} end,
        function() hooks["GmodIntegration:Websocket:Restart"]["gmInte:Rewards:Restart"]() end,
        function() now = now + 8 * 86400 end,
    }) do
        reset()
        local value, request = luaDelivery(), poll()
        change(); request.success(200, { deliveries = { value } })
        assert(players[1].luaCalls == nil and #compilations == 0 and next(rows) == nil)
    end
end)

test("Lua actions can complete alongside an economy action without changing the fixed adapter", function()
    reset()
    local value = luaDelivery()
    value.actions[2] = { id = "96c949d4-92a8-4674-a762-8d4ce1feb379", type = "darkrp_money", amount = 500 }
    local ack = respond(value)
    assert(players[1].luaCalls == 1 and players[1].money == 600 and #effects == 1 and #messages == 1)
    assert(#ack.body.results == 2 and ack.body.results[1].status == "delivered" and ack.body.results[2].status == "delivered")
end)

os.time = realTime
if #failures > 0 then error(table.concat(failures, "\n")) end
print("rewards_spec: " .. passes .. " checks passed")
