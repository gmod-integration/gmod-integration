local MAX_PLAYERS, MAX_DELIVERIES, MAX_ACTIONS = 64, 10, 5
local MAX_AMOUNT, MAX_JOURNAL, MAX_LUA_BYTES = 1000000, 100000, 65536
local DAY = 86400
local generation, active, stopped = 0, nil, false
local playerOffset = 0
local nextWarning = 0
local availableAt = setmetatable({}, { __mode = "k" })
local tableName = "gm_integration_reward_actions"

local function warning()
    if SysTime() < nextWarning then return end
    nextWarning = SysTime() + 60
    gmInte.logWarning("Rewards delivery could not be confirmed; inspect its status in the dashboard.")
end

local function exactKeys(value, allowed)
    if !istable(value) then return false end
    for key in pairs(value) do if !allowed[key] then return false end end
    return true
end

local function boundedString(value, maximum)
    return isstring(value) && #value > 0 && #value <= maximum && !string.find(value, "[%z\1-\31\127]")
end

local function uuid(value)
    return isstring(value) && #value == 36 && string.match(value, "^%x%x%x%x%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%-%x%x%x%x%x%x%x%x%x%x%x%x$") != nil
end

local function steamID(value)
    return isstring(value) && #value == 17 && string.sub(value, 1, 7) == "7656119" && string.match(value, "^%d+$") != nil
end

local function array(value, maximum)
    if !istable(value) then return false end
    local count = 0
    for key in pairs(value) do
        if !isnumber(key) || key % 1 != 0 || key < 1 || key > maximum then return false end
        count = count + 1
    end
    return count == #value && count <= maximum
end

local function query(statement)
    if !istable(sql) || !isfunction(sql.Query) || !isfunction(sql.SQLStr) then return false end
    local ok, result = pcall(sql.Query, statement)
    if !ok || result == false then warning() return false end
    return result
end

local function prepareJournal()
    if query("CREATE TABLE IF NOT EXISTS " .. tableName .. " (journal_key TEXT PRIMARY KEY, fingerprint TEXT NOT NULL, status TEXT NOT NULL, reason TEXT NOT NULL, expires_at INTEGER NOT NULL)") == false then return false end
    if query("CREATE INDEX IF NOT EXISTS gm_integration_reward_expiry ON " .. tableName .. " (expires_at)") == false then return false end
    -- Expired payloads are rejected below; one extra day retains late acknowledgements for diagnosis.
    return query("DELETE FROM " .. tableName .. " WHERE expires_at < " .. tostring(os.time() - DAY)) != false
end

local function journalRead(key)
    local rows = query("SELECT fingerprint, status, reason FROM " .. tableName .. " WHERE journal_key = " .. sql.SQLStr(key))
    if rows == false then return false end
    if rows == nil then return nil end
    if !istable(rows) || !istable(rows[1]) || rows[2] != nil then return false end
    return rows[1]
end

local function current(request)
    return !stopped && generation == request.generation && gmInte.aprovedCredentials == true &&
        request.serverID == gmInte.config.id && request.token == gmInte.config.token &&
        request.host == gmInte.config.websocketFQDN && request.socket == gmInte.websocket
end

local function integrations()
    local meta = FindMetaTable("Player") || {}
    return {
        darkrp = istable(DarkRP) && isfunction(meta.addMoney),
        pointshop = istable(PS) && isfunction(meta.PS_GivePoints),
        pointshop2 = istable(Pointshop2) && isfunction(meta.PS2_AddStandardPoints),
    }
end

local actionTypes = { darkrp_money = true, pointshop_points = true, pointshop2_points = true }
local function luaSource(value)
    return isstring(value) && #value > 0 && #value <= MAX_LUA_BYTES &&
        string.find(value, "%S") != nil && !string.find(value, "\0", 1, true)
end

local function validateDeliveries(body, request)
    if !exactKeys(body, { deliveries = true }) || !array(body.deliveries, MAX_DELIVERIES) then return false end
    local seen = {}
    for _, delivery in ipairs(body.deliveries) do
        if !exactKeys(delivery, { id = true, token = true, steamID64 = true, ruleName = true, expiresAt = true, actions = true }) ||
            !uuid(delivery.id) || !uuid(delivery.token) || !steamID(delivery.steamID64) || !request.players[delivery.steamID64] ||
            -- Backend names allow 80 Unicode characters; GLua string lengths count UTF-8 bytes.
            !boundedString(delivery.ruleName, 320) || !isnumber(delivery.expiresAt) || delivery.expiresAt % 1 != 0 ||
            delivery.expiresAt <= os.time() || delivery.expiresAt > os.time() + 31 * DAY ||
            !array(delivery.actions, MAX_ACTIONS) || #delivery.actions == 0 || seen[delivery.id] then return false end
        seen[delivery.id] = true
        local ids = {}
        for _, action in ipairs(delivery.actions) do
            if !istable(action) || !uuid(action.id) || ids[action.id] then return false end
            if action.type == "lua" then
                if !exactKeys(action, { id = true, type = true, code = true }) || !luaSource(action.code) then return false end
            elseif !exactKeys(action, { id = true, type = true, amount = true }) || !actionTypes[action.type] ||
                !isnumber(action.amount) || action.amount % 1 != 0 || action.amount < 1 || action.amount > MAX_AMOUNT then
                return false
            end
            ids[action.id] = true
        end
    end
    return true
end

local function actionResult(action, status, reason)
    return { id = action.id, status = status, reason = reason }
end

local function creditFunction(ply, action)
    local value, fn
    if action.type == "darkrp_money" && istable(DarkRP) && isfunction(ply.addMoney) && isfunction(ply.getDarkRPVar) && !ply.DarkRPUnInitialized then
        value, fn = ply:getDarkRPVar("money"), ply.addMoney
    elseif action.type == "pointshop_points" && istable(PS) && isfunction(ply.PS_GivePoints) then
        value, fn = ply.PS_Points, ply.PS_GivePoints
    elseif action.type == "pointshop2_points" && istable(Pointshop2) && isfunction(ply.PS2_AddStandardPoints) && istable(ply.PS2_Wallet) then
        value, fn = ply.PS2_Wallet.points, ply.PS2_AddStandardPoints
    end
    if !isnumber(value) || value != value || value < 0 || value + action.amount > 2147483647 then return nil end
    return fn
end

local function fingerprint(delivery, action)
    local content = tostring(action.amount)
    if action.type == "lua" then
        if !istable(util) || !isfunction(util.SHA256) then return nil end
        local ok, hash = pcall(util.SHA256, action.code)
        if !ok || !isstring(hash) || #hash != 64 || !string.match(hash, "^%x+$") then return nil end
        content = string.lower(hash)
    end
    return delivery.steamID64 .. "/" .. action.type .. "/" .. content .. "/" .. tostring(delivery.expiresAt)
end

local function prepareAction(ply, delivery, action)
    if action.type == "lua" then
        if !isfunction(CompileString) then return nil, "pending", "lua_unavailable" end
        -- CompileString does not execute the chunk. Locals receive real values instead of source substitutions.
        local ok, compiled = pcall(CompileString,
            "local ply, reward = ...\nlocal steamID64 = reward.steamID64\n" .. action.code,
            "GMI Reward " .. action.id, false)
        if !ok || !isfunction(compiled) then return nil, "failed", "lua_compile_failed" end
        local context = { id = delivery.id, actionID = action.id, name = delivery.ruleName, steamID64 = delivery.steamID64 }
        return function() return compiled(ply, context) end
    end
    local ready, credit = pcall(creditFunction, ply, action)
    if !ready || !isfunction(credit) then return nil, "pending", "integration_unavailable" end
    return function() return credit(ply, action.amount) end
end

local function applyAction(request, delivery, action)
    local key = request.serverID .. "/" .. delivery.id .. "/" .. action.id
    local contentFingerprint = fingerprint(delivery, action)
    if !contentFingerprint then return actionResult(action, "pending", "lua_unavailable") end
    local saved = journalRead(key)
    if saved == false then return actionResult(action, "pending", "journal_unavailable") end
    if saved != nil then
        if saved.fingerprint != contentFingerprint then warning() return actionResult(action, "uncertain", "execution_uncertain") end
        if saved.status == "delivered" || saved.status == "failed" then return actionResult(action, saved.status, saved.reason != "" && saved.reason || nil) end
        -- A process can stop after an action's effects and before recording success. Never replay it.
        return actionResult(action, "uncertain", "execution_uncertain")
    end
    local ply = player.GetBySteamID64(delivery.steamID64)
    if !IsValid(ply) || !ply:IsPlayer() || ply:IsBot() then return actionResult(action, "pending", "player_offline") end
    if availableAt[ply] && SysTime() < availableAt[ply] then return actionResult(action, "pending", "integration_unavailable") end
    local execute, preparationStatus, preparationReason = prepareAction(ply, delivery, action)
    if !execute then return actionResult(action, preparationStatus, preparationReason) end
    local count = query("SELECT COUNT(*) AS total FROM " .. tableName)
    if !istable(count) || !count[1] || !tonumber(count[1].total) || tonumber(count[1].total) >= MAX_JOURNAL then
        warning() return actionResult(action, "pending", "journal_unavailable")
    end
    if !current(request) then return nil end
    if query("INSERT INTO " .. tableName .. " (journal_key, fingerprint, status, reason, expires_at) VALUES (" ..
        sql.SQLStr(key) .. ", " .. sql.SQLStr(contentFingerprint) .. ", 'started', '', " .. tostring(delivery.expiresAt) .. ")") == false then
        return actionResult(action, "pending", "journal_unavailable")
    end
    saved = journalRead(key)
    if !istable(saved) || saved.fingerprint != contentFingerprint || saved.status != "started" then
        warning() return actionResult(action, "uncertain", "execution_uncertain")
    end
    -- Authorized server-side actions start only after their durable reservation has been verified.
    local ok, accepted = pcall(execute)
    local status = ok && accepted != false && "delivered" || "uncertain"
    local reason = status == "uncertain" && (action.type == "lua" && "lua_execution_failed" || "execution_uncertain") || ""
    if query("UPDATE " .. tableName .. " SET status = " .. sql.SQLStr(status) .. ", reason = " .. sql.SQLStr(reason) ..
        " WHERE journal_key = " .. sql.SQLStr(key) .. " AND status = 'started'") == false then
        return actionResult(action, "uncertain", "execution_uncertain")
    end
    saved = journalRead(key)
    if !istable(saved) || saved.status != status then return actionResult(action, "uncertain", "execution_uncertain") end
    return actionResult(action, status, reason != "" && reason || nil), status == "delivered"
end

local function receive(request, body)
    if !current(request) || !validateDeliveries(body, request) then return end
    local journalReady = prepareJournal()
    for _, delivery in ipairs(body.deliveries) do
        if !current(request) then return end
        local results, newlyDelivered, complete = {}, false, true
        for _, action in ipairs(delivery.actions) do
            local result, fresh
            if journalReady then result, fresh = applyAction(request, delivery, action)
            else result = actionResult(action, "pending", "journal_unavailable") end
            if !result then return end
            results[#results + 1] = result
            newlyDelivered = newlyDelivered || fresh == true
            complete = complete && result.status == "delivered"
        end
        if !current(request) then return end
        gmInte.api.post("/servers/:serverID/rewards/ack", { id = delivery.id, token = delivery.token, results = results }, nil, function()
            if current(request) then warning() end
        end)
        if newlyDelivered && complete then
            local ply = player.GetBySteamID64(delivery.steamID64)
            if IsValid(ply) && isfunction(ply.ChatPrint) then
                pcall(ply.ChatPrint, ply, gmInte.getTranslation("rewards.received", "Reward received: {1}", delivery.ruleName))
            end
        end
    end
end

local function poll()
    if stopped || gmInte.aprovedCredentials != true || !boundedString(gmInte.config.id, 128) || !boundedString(gmInte.config.token, 1024) then return end
    if active && SysTime() < active.deadline then return end
    local list, identities = {}, {}
    local online = player.GetAll()
    for index = 1, #online do
        local ply = online[(playerOffset + index - 1) % #online + 1]
        if IsValid(ply) && ply:IsPlayer() && !ply:IsBot() && steamID(ply:SteamID64()) && #list < MAX_PLAYERS then
            local id = ply:SteamID64()
            if !identities[id] then list[#list + 1], identities[id] = id, true end
        end
    end
    if #online > 0 then playerOffset = (playerOffset + MAX_PLAYERS) % #online end
    local request = {
        serverID = gmInte.config.id, token = gmInte.config.token, host = gmInte.config.websocketFQDN,
        socket = gmInte.websocket, generation = generation, players = identities, deadline = SysTime() + 35,
    }
    active = request
    gmInte.api.post("/servers/:serverID/rewards/poll", { integrations = integrations(), players = list }, function(_, body)
        if active != request then return end
        active = nil
        receive(request, body)
    end, function()
        if active == request then active = nil end
    end)
end

hook.Add("PlayerInitialSpawn", "gmInte:Rewards:PlayerReady", function(ply)
    availableAt[ply] = SysTime() + 10
    timer.Simple(10, poll)
end)
hook.Add("GmodIntegration:Websocket:Ready", "gmInte:Rewards:Ready", function()
    generation = generation + 1
    active = nil
    timer.Simple(2, poll)
end)
hook.Add("GmodIntegration:Websocket:Restart", "gmInte:Rewards:Restart", function()
    generation = generation + 1
    active = nil
end)
hook.Add("ShutDown", "gmInte:Rewards:Shutdown", function()
    stopped = true
    active = nil
end)
timer.Create("gmInte:Rewards:Poll", 30, 0, poll)
