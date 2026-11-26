-- Run the real player filter with engine/API mocks, including late replies and reconnects.
local clock, hooks, timers, requests, actors, kicks, identities, nextUserID, playerMeta, deferred
local passed = 0
local ID = '76561198000000001'

local function reset(options)
    options = options or {}
    clock, hooks, timers, requests, actors, kicks, identities, nextUserID = 1000, {}, {}, {}, {}, {}, {}, 0
    deferred = {}
    SERVER, CLIENT = true, false
    isstring = function(value) return type(value) == 'string' end
    istable = function(value) return type(value) == 'table' end
    isnumber = function(value) return type(value) == 'number' end
    isfunction = function(value) return type(value) == 'function' end
    isbool = function(value) return type(value) == 'boolean' end
    IsValid = function(value) return type(value) == 'table' and value.valid == true end
    SysTime = function() return clock end
    HTTP = function() error('No HTTP fallback is permitted') end
    http = { Fetch = HTTP }
    hook = {
        Add = function(event, id, callback)
            hooks[event] = hooks[event] or {}
            hooks[event][id] = callback
        end,
        Run = function(event, ...)
            for _, callback in pairs(hooks[event] or {}) do callback(...) end
        end,
    }
    timer = {
        Create = function(id, _, _, callback) timers[id] = callback end,
        Simple = function(_, callback) deferred[#deferred + 1] = callback end,
    }
    gameevent = { Listen = function() end }
    game = { KickID = function(networkID, reason) kicks[#kicks + 1] = { networkID = networkID, reason = reason } end }
    player = {
        GetAll = function()
            local online = {}
            for _, ply in ipairs(actors) do if ply.valid and ply.online then online[#online + 1] = ply end end
            return online
        end,
        GetBySteamID64 = function(id)
            for _, ply in ipairs(actors) do if ply.valid and ply.online and ply:SteamID64() == id then return ply end end
        end,
    }
    util = {
        SteamIDTo64 = function(networkID) return identities[networkID] or '0' end,
        TableToJSON = function() return '{}' end,
    }
    file = { Write = function() end }
    gmInte = {
        config = {
            maintenance = options.maintenance ~= false, adminRank = { superadmin = true },
            forcePlayerLink = options.link == true, verifyOnJoin = options.link == true,
            filterOnBan = true, syncBan = true, supportLink = '',
        },
        aprovedCredentials = true,
        getTranslation = function(key, fallback, argument)
            return key .. ':' .. (argument and fallback:gsub('{1}', function() return argument end) or fallback)
        end,
        logWarning = function() end, logError = function() end, SendNet = function() end,
        hasWebsocketModule = function() return true end,
        compareVersion = function() return 0 end,
        api = {
            get = function(endpoint, success, failed)
                local request = { endpoint = endpoint }
                request.success = function(code, body) request.done = true; success(code, body) end
                request.failed = function(code, body) request.done = true; failed(code, body) end
                requests[#requests + 1] = request
                return 'request:' .. #requests
            end,
            post = function(_, _, success) if success then success(200, {}) end end,
        },
    }
    playerMeta = {}
    FindMetaTable = function() return playerMeta end
    loadGLua('lua/gmod_integration/core/utils/sh_player_meta.lua')
    loadGLua('lua/gmod_integration/modules/players_filter_whitelist/sv_filtrers.lua')
end

local function actor(id, group, online)
    nextUserID = nextUserID + 1
    local ply = setmetatable({ valid = true, online = online ~= false, id = id or ID, group = group or 'user', userID = nextUserID, kicks = {} }, { __index = playerMeta })
    ply.networkID = 'STEAM_0:1:' .. tostring(nextUserID)
    identities[ply.networkID] = ply.id
    function ply:IsPlayer() return true end
    function ply:IsBot() return self.bot == true end
    function ply:SteamID64() return self.id end
    function ply:UserID() return self.userID end
    function ply:GetUserGroup() return self.group end
    function ply:Kick(reason) self.kicks[#self.kicks + 1] = reason end
    actors[#actors + 1] = ply
    return ply
end

local function flushDeferred()
    local callbacks = deferred
    deferred = {}
    for _, callback in ipairs(callbacks) do callback() end
end

local function spawn(ply)
    ply.online = true
    hook.Run('PlayerInitialSpawn', ply)
    flushDeferred()
end

local function join(ply, shouldSpawn)
    hook.Run('player_connect', { networkid = ply.networkID, userid = ply.userID, bot = ply.bot and 1 or 0 })
    if shouldSpawn ~= false then spawn(ply) end
end

local function disconnect(ply, early)
    ply.online = false
    if early then
        hook.Run('player_disconnect', { networkid = ply.networkID, userid = ply.userID })
    else
        hook.Run('PlayerDisconnected', ply)
    end
    ply.valid = false
end

local function success(index, changes)
    local body = { bypassMaintenance = false, discordAdmin = false }
    for key, value in pairs(changes or {}) do body[key] = value end
    requests[index].success(200, body)
end

local function refresh(id)
    gmInte.wsRefreshPlayerAccess({ method = 'wsRefreshPlayerAccess', steamID = id })
end

local function tick(seconds)
    clock = clock + seconds
    if timers['gmInte:Config:RetrySync'] then timers['gmInte:Config:RetrySync']() end
    timers['gmInte:Player:RefreshAccess']()
end

local function ready()
    hook.Run('GmodIntegration:Websocket:Ready')
    -- These filter-only tests model a completed authoritative configuration sync.
    hook.Run('GmodIntegration:Config:Synchronized')
end

local function remoteConfig(index, enabled)
    requests[index].success(200, { settings = { ig_maintenance = enabled, ig_adminRank = { superadmin = true } } })
end

local function outstanding()
    local count = 0
    for _, request in ipairs(requests) do if not request.done then count = count + 1 end end
    return count
end

local function test(name, callback)
    reset()
    local ok, problem = pcall(callback)
    assert(ok, name .. ': ' .. tostring(problem))
    passed = passed + 1
    print('ok whitelist: ' .. name)
end

test('every connection gets fresh access and cannot reuse a recent role grant', function()
    local first = actor()
    join(first)
    assert(#requests == 1 and requests[1].endpoint == '/servers/:serverID/players/' .. ID .. '/access')
    success(1, { bypassMaintenance = true, roleBypassMaintenance = true, manualBypassMaintenance = false })
    assert(#first.kicks == 0)
    disconnect(first)
    local second = actor()
    join(second)
    assert(#requests == 2)
    success(2)
    assert(#second.kicks == 1 and second.kicks[1]:find('filter.maintenance', 1, true), 'player kicks=' .. #second.kicks .. ' network kicks=' .. #kicks)
end)

test('new joins fail closed for provider failure, timeout and malformed success', function()
    for _, response in ipairs({ 'failure', 'timeout', 'empty', 'string', 'missing', 'wrongBoolean' }) do
        reset()
        local ply = actor()
        join(ply)
        if response == 'failure' then requests[1].failed(503, {})
        elseif response == 'timeout' then requests[1].failed(504, {})
        elseif response == 'empty' then requests[1].success(200, nil)
        elseif response == 'string' then requests[1].success(200, 'denied')
        elseif response == 'missing' then requests[1].success(200, { bypassMaintenance = false })
        else requests[1].success(200, { bypassMaintenance = 'true', discordAdmin = false }) end
        assert(#ply.kicks == 1, response)
    end
end)

test('manual, Discord administrator and local administrator exemptions remain effective', function()
    for _, exemption in ipairs({ 'manual', 'discordAdmin', 'localAdmin' }) do
        reset()
        local ply = actor(nil, exemption == 'localAdmin' and 'superadmin' or 'user')
        join(ply)
        if exemption == 'localAdmin' then requests[1].failed(503, {})
        else success(1, { bypassMaintenance = exemption == 'manual', discordAdmin = exemption == 'discordAdmin' }) end
        assert(#ply.kicks == 0, exemption)
    end
end)

test('whitelist-disabled joins keep existing ban filters and do not kick on an outage', function()
    for _, reason in ipairs({ 'outage', 'ban', 'discord_ban' }) do
        reset({ maintenance = false })
        local ply = actor()
        join(ply)
        assert(requests[1].endpoint == '/servers/:serverID/players/' .. ID)
        if reason == 'outage' then requests[1].failed(503, {}) else requests[1].success(200, { [reason] = true }) end
        assert(#ply.kicks == (reason == 'outage' and 0 or 1), reason)
        if reason ~= 'outage' then assert(ply.kicks[1]:find('filter.' .. reason, 1, true)) end
    end
end)

test('a targeted refresh checks only its online player and ignores invalid or unknown identities', function()
    local target = actor()
    local other = actor('76561198000000002')
    refresh(ID)
    assert(#requests == 1 and requests[1].endpoint == '/servers/:serverID/players/' .. ID .. '/access')
    refresh('76561198000000999')
    refresh('invalid')
    gmInte.wsRefreshPlayerAccess({ steamID = 76561198000000001 })
    assert(#requests == 1)
    success(1, { bypassMaintenance = true })
    assert(#target.kicks == 0 and #other.kicks == 0)
end)

test('join-time local administrators retain their exemption on a provider failure', function()
    local ply = actor(nil, 'superadmin', false)
    join(ply, false)
    assert(#requests == 0)
    spawn(ply)
    requests[1].failed(503, {})
    assert(#kicks == 0 and #ply.kicks == 0)
end)

test('refreshes cannot bypass waiting for the real rank assigned by spawn hooks', function()
    local ply = actor(nil, 'user', false)
    join(ply, false)
    ply.online = true
    refresh(ID)
    refresh()
    tick(30)
    assert(#requests == 0 and #kicks == 0)
    hook.Add('PlayerInitialSpawn', 'fixture:assignActualRank', function(joining) joining.group = 'superadmin' end)
    spawn(ply)
    assert(#requests == 1)
    success(1)
    assert(ply.group == 'superadmin' and #ply.kicks == 0 and #kicks == 0)
end)

test('unknown ranks gain no event-supplied exemption and ordinary joins still fail closed', function()
    local ply = actor(nil, 'user', false)
    hook.Run('player_connect', { networkid = ply.networkID, userid = ply.userID, bot = 0, rank = 'superadmin' })
    assert(#requests == 0)
    ply.group = nil
    spawn(ply)
    refresh()
    tick(1)
    assert(#requests == 0 and #kicks == 0)
    ply.group = 'user'
    tick(1)
    assert(#requests == 1)
    requests[1].failed(503, {})
    assert(#ply.kicks == 1)
end)

test('a deferred spawn from a disconnected session cannot act on a replacement connection', function()
    local old = actor(nil, nil, false)
    join(old, false)
    old.online = true
    hook.Run('PlayerInitialSpawn', old)
    assert(#requests == 0)
    disconnect(old)
    local ply = actor(nil, nil, false)
    join(ply, false)
    flushDeferred()
    assert(#requests == 0 and #kicks == 0 and #ply.kicks == 0)
    spawn(ply)
    assert(#requests == 1)
    success(1)
    assert(#ply.kicks == 1)
end)

test('changing mode before a join reply chooses a fresh endpoint and ignores the old answer', function()
    reset({ maintenance = false })
    local ply = actor()
    join(ply)
    assert(requests[1].endpoint == '/servers/:serverID/players/' .. ID)
    gmInte.config.maintenance = true
    requests[1].success(200, {})
    assert(#ply.kicks == 0 and #requests == 2)
    assert(requests[2].endpoint == '/servers/:serverID/players/' .. ID .. '/access')
    success(2, { bypassMaintenance = true })
    assert(#ply.kicks == 0)
end)

test('existing account-link checks still deny unlinked players and ignore an old session reply', function()
    reset({ link = true })
    local old = actor()
    join(old)
    assert(#requests == 2 and requests[1].endpoint == '/users?steamID64=' .. ID)
    success(2, { bypassMaintenance = true })
    disconnect(old)
    local ply = actor()
    join(ply)
    requests[1].failed(404, {})
    assert(#ply.kicks == 0)
    success(4, { bypassMaintenance = true })
    requests[3].success(200, {})
    assert(#ply.kicks == 1 and ply.kicks[1]:find('filter.link', 1, true))
end)

test('bots and invalid identities never issue access requests', function()
    local bot = actor()
    bot.bot = true
    join(bot)
    join(actor('0'))
    hook.Run('player_connect', { networkid = false })
    assert(#requests == 0)
end)

test('an online explicit denial kicks while a manual or Discord-admin grant does not', function()
    for _, grant in ipairs({ 'none', 'manual', 'discordAdmin' }) do
        reset()
        local ply = actor()
        refresh(ID)
        assert(#requests == 1)
        success(1, { bypassMaintenance = grant == 'manual', discordAdmin = grant == 'discordAdmin' })
        assert(#ply.kicks == (grant == 'none' and 1 or 0), grant)
    end
end)

test('online provider failures, timeouts and malformed responses retry without blind kicks', function()
    for _, response in ipairs({ 'failure', 'timeout', 'empty', 'missing', 'wrongBoolean', 'wrongStatus' }) do
        reset()
        local ply = actor()
        refresh(ID)
        if response == 'failure' then requests[1].failed(503, {})
        elseif response == 'timeout' then requests[1].failed(504, {})
        elseif response == 'empty' then requests[1].success(200, nil)
        elseif response == 'missing' then requests[1].success(200, { bypassMaintenance = false })
        elseif response == 'wrongStatus' then requests[1].success(503, { bypassMaintenance = false, discordAdmin = false })
        else requests[1].success(200, { bypassMaintenance = false, discordAdmin = 0 }) end
        assert(#ply.kicks == 0 and #requests == 1, response)
        tick(9)
        assert(#requests == 1)
        tick(1)
        assert(#requests == 2 and #ply.kicks == 0)
        success(2)
        assert(#ply.kicks == 1)
    end
end)

test('notifications coalesce and online work remains bounded at two actual requests', function()
    for i = 1, 6 do actor('7656119800000000' .. i) end
    refresh()
    assert(#requests == 2 and outstanding() == 2)
    for _ = 1, 100 do refresh() end
    assert(#requests == 2 and outstanding() == 2)
    local i = 1
    while i <= #requests do
        success(i, { bypassMaintenance = true })
        assert(outstanding() <= 2)
        i = i + 1
        assert(i <= 10)
    end
    assert(#requests == 8 and outstanding() == 0)
    for _, ply in ipairs(actors) do assert(#ply.kicks == 0) end
end)

test('a role notification invalidates an old denial before a fresh grant', function()
    local ply = actor()
    refresh(ID)
    refresh(ID)
    success(1)
    assert(#ply.kicks == 0 and #requests == 2)
    success(2, { bypassMaintenance = true })
    assert(#ply.kicks == 0)
end)

test('a role loss invalidates an old grant and observes the fresh denial', function()
    local ply = actor()
    refresh(ID)
    refresh(ID)
    success(1, { bypassMaintenance = true })
    assert(#requests == 2 and #ply.kicks == 0)
    success(2)
    assert(#ply.kicks == 1)
end)

test('an in-progress join is also invalidated by a targeted role change', function()
    local ply = actor()
    join(ply)
    refresh(ID)
    success(1)
    assert(#requests == 2 and #kicks == 0)
    success(2, { bypassMaintenance = true })
    assert(#kicks == 0)
end)

test('old join failures and denials cannot kick a reconnect with the same Steam ID', function()
    for _, failed in ipairs({ false, true }) do
        reset()
        local old = actor()
        join(old)
        disconnect(old, true)
        local ply = actor()
        join(ply)
        if failed then requests[1].failed(503, {}) else success(1) end
        assert(#kicks == 0)
        success(2, { bypassMaintenance = true })
        assert(#kicks == 0)
    end
end)

test('a late disconnect from an old player cannot remove the new session', function()
    local old = actor()
    join(old)
    local ply = actor()
    join(ply)
    hook.Run('PlayerDisconnected', old)
    hook.Run('player_disconnect', { networkid = old.networkID, userid = old.userID })
    success(1)
    assert(#ply.kicks == 0)
    success(2)
    assert(#ply.kicks == 1)
end)

test('disconnect cleanup removes queued players and releases completed old work slots', function()
    actor()
    actor('76561198000000002')
    actor('76561198000000003')
    refresh()
    assert(#requests == 2)
    local first, second, queued
    for _, ply in ipairs(actors) do
        if requests[1].endpoint:find(ply.id, 1, true) then first = ply
        elseif requests[2].endpoint:find(ply.id, 1, true) then second = ply
        else queued = ply end
    end
    disconnect(queued)
    disconnect(first)
    success(1)
    success(2, { bypassMaintenance = true })
    assert(#requests == 2 and outstanding() == 0)
    local new = actor(first.id)
    refresh(first.id)
    assert(#requests == 3)
    success(3, { bypassMaintenance = true })
    assert(#new.kicks == 0 and #first.kicks == 0 and #second.kicks == 0)
end)

test('WebSocket readiness supersedes previous answers and rechecks current online players', function()
    local ply = actor()
    refresh(ID)
    ready()
    success(1)
    assert(#ply.kicks == 0 and #requests == 2)
    success(2, { bypassMaintenance = true })
    ready()
    assert(#requests == 3)
    success(3)
    assert(#ply.kicks == 1)
end)

test('a thirty-second sweep recovers a missed role notification', function()
    local ply = actor()
    tick(29)
    assert(#requests == 0)
    tick(1)
    assert(#requests == 1)
    success(1, { bypassMaintenance = true })
    tick(30)
    assert(#requests == 2)
    success(2)
    assert(#ply.kicks == 1)
end)

test('offline retries wait for authentication and are refreshed on reconnect', function()
    local ply = actor()
    refresh(ID)
    gmInte.aprovedCredentials = false
    requests[1].failed(503, {})
    tick(30)
    assert(#requests == 1 and #ply.kicks == 0)
    gmInte.aprovedCredentials = true
    ready()
    assert(#requests == 2)
    success(2, { bypassMaintenance = true })
end)

test('local rank exemptions use the live group immediately before an online denial', function()
    local ply = actor()
    refresh(ID)
    ply.group = 'superadmin'
    success(1)
    assert(#ply.kicks == 0)
    tick(30)
    assert(#requests == 1)
    ply.group = 'user'
    tick(30)
    assert(#requests == 2)
    success(2)
    assert(#ply.kicks == 1)
end)

test('saved whitelist and administrator settings invalidate pending replies immediately', function()
    reset({ maintenance = false })
    local ply = actor()
    loadGLua('lua/gmod_integration/core/config/sv_settings.lua')
    assert(gmInte.saveSetting('maintenance', true))
    assert(#requests == 1)
    assert(gmInte.saveSetting('maintenance', false))
    success(1)
    assert(#ply.kicks == 0)
    assert(gmInte.saveSetting('maintenance', true))
    assert(#requests == 2)
    assert(gmInte.saveSetting('adminRank', { user = true }))
    success(2)
    assert(#ply.kicks == 0 and #requests == 2)
    assert(gmInte.saveSetting('adminRank', { superadmin = true }))
    assert(#requests == 3)
    success(3)
    assert(#ply.kicks == 1)
end)

test('direct whitelist toggles also invalidate callbacks and disabled mode never polls', function()
    local ply = actor()
    refresh(ID)
    gmInte.config.maintenance = false
    tick(1)
    success(1)
    tick(60)
    assert(#requests == 1 and #ply.kicks == 0)
    gmInte.config.maintenance = true
    tick(1)
    assert(#requests == 2)
    success(2)
    assert(#ply.kicks == 1)
end)

test('reconnect waits for disabled remote mode before it can act on an online denial', function()
    local ply = actor()
    refresh(ID)
    loadGLua('lua/gmod_integration/core/config/sv_settings.lua')
    hook.Run('GmodIntegration:Websocket:Ready')
    assert(#requests == 2 and requests[2].endpoint == '/servers/:serverID/config')
    success(1)
    assert(#ply.kicks == 0 and #requests == 2)
    remoteConfig(2, false)
    tick(60)
    assert(gmInte.config.maintenance == false and #ply.kicks == 0 and #requests == 2)
end)

test('unknown reconnect configuration retries without using the stale local mode to kick', function()
    local ply = actor()
    loadGLua('lua/gmod_integration/core/config/sv_settings.lua')
    hook.Run('GmodIntegration:Websocket:Ready')
    assert(#requests == 1 and requests[1].endpoint == '/servers/:serverID/config')
    requests[1].failed(503, {})
    tick(9)
    assert(#requests == 1 and #ply.kicks == 0)
    tick(1)
    assert(#requests == 2 and requests[2].endpoint == '/servers/:serverID/config')
    requests[2].success(200, {})
    tick(10)
    assert(#requests == 3 and requests[3].endpoint == '/servers/:serverID/config' and #ply.kicks == 0)
    remoteConfig(3, true)
    assert(#requests == 4 and requests[4].endpoint:find('/access', 1, true))
    requests[4].failed(503, {})
    assert(#ply.kicks == 0)
    tick(10)
    assert(#requests == 5 and requests[5].endpoint:find('/access', 1, true))
    success(5)
    assert(#ply.kicks == 1)
end)

test('a previous reconnect config reply cannot change policy or release the current gate', function()
    local ply = actor()
    loadGLua('lua/gmod_integration/core/config/sv_settings.lua')
    hook.Run('GmodIntegration:Websocket:Ready')
    hook.Run('GmodIntegration:Websocket:Ready')
    assert(#requests == 2)
    remoteConfig(1, true)
    assert(gmInte.config.maintenance == true and #requests == 2 and #ply.kicks == 0)
    remoteConfig(2, false)
    remoteConfig(1, true)
    tick(30)
    assert(gmInte.config.maintenance == false and #requests == 2 and #ply.kicks == 0)
end)

test('a newer remote policy edit cannot be overwritten by the pending reconnect snapshot', function()
    for _, setting in ipairs({ 'ig_maintenance', 'ig_adminRank' }) do
        reset()
        local ply = actor()
        loadGLua('lua/gmod_integration/core/config/sv_settings.lua')
        hook.Run('GmodIntegration:Websocket:Ready')
        assert(#requests == 1)
        local value = { user = true }
        if setting == 'ig_maintenance' then value = false end
        gmInte.wsEditSetting({ setting = setting, value = value })
        remoteConfig(1, true)
        assert(#requests == 1 and #ply.kicks == 0)
        if setting == 'ig_maintenance' then assert(gmInte.config.maintenance == false)
        else assert(ply:gmIntIsAdmin()) end
        tick(10)
        assert(#requests == 2 and requests[2].endpoint == '/servers/:serverID/config')
        requests[2].success(200, { settings = {
            ig_maintenance = setting ~= 'ig_maintenance',
            ig_adminRank = setting == 'ig_adminRank' and { user = true } or { superadmin = true },
        } })
        assert(#requests == 2 and #ply.kicks == 0)
    end
end)

test('a current local configuration upload also reconciles the online-check gate', function()
    reset({ maintenance = false })
    local ply = actor()
    loadGLua('lua/gmod_integration/core/config/sv_settings.lua')
    gmInte.api.post = function(endpoint, body, successCallback, failedCallback)
        requests[#requests + 1] = { endpoint = endpoint, body = body, success = successCallback, failed = failedCallback }
    end
    gmInte.aprovedCredentials = false
    assert(gmInte.saveSetting('maintenance', true))
    gmInte.aprovedCredentials = true
    hook.Run('GmodIntegration:Websocket:Ready')
    assert(#requests == 1 and requests[1].body.maintenance == true)
    requests[1].success(200, {})
    assert(#requests == 2 and requests[2].endpoint:find('/access', 1, true))
    success(2)
    assert(#ply.kicks == 1)
end)

print('Whitelist regressions: ' .. passed .. ' passed')
