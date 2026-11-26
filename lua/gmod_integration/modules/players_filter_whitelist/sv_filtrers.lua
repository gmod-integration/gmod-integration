local function filterMessage(reason)
    local Message = {}
    table.insert(Message, "----------------------------------------")
    table.insert(Message, gmInte.getTranslation("filter.ds.1", "You cannot join this server"))
    table.insert(Message, "")
    table.insert(Message, gmInte.getTranslation("filter.ds.2", "Reason: {1}", reason && reason || gmInte.getTranslation("filter.none", "none")))
    if gmInte.config.supportLink && gmInte.config.supportLink != "" then table.insert(Message, gmInte.getTranslation("filter.ds.3", "Help URL: {1}", gmInte.config.supportLink)) end
    table.insert(Message, "")
    table.insert(Message, gmInte.getTranslation("filter.ds.4", "Have a nice day"))
    table.insert(Message, "----------------------------------------")
    table.insert(Message, gmInte.getTranslation("filter.ds.5", "Service provided by Gmod Integration"))
    for k, v in ipairs(Message) do
        Message[k] = "\n" .. v
    end
    return table.concat(Message)
end

local sessions = {}
local activeOnline = 0
local pumping = false
local queueSequence = 0
local previousMaintenance = gmInte.config.maintenance
local lastSweep = SysTime()
local onlineConfigReady = true
local pump

local function steamID64(value)
    return isstring(value) && #value == 17 && string.match(value, "^%d+$") != nil
end

local function validPlayer(ply)
    return IsValid(ply) && ply:IsPlayer() && !ply:IsBot()
end

local function localAdmin(session)
    return validPlayer(session.ply) && session.ply:gmIntIsAdmin() || false
end

local function current(session)
    return sessions[session.steamID64] == session && (!session.ply || validPlayer(session.ply))
end

local function whitelistMessage()
    return filterMessage(gmInte.getTranslation("filter.maintenance", "Whitelist mode is enabled and you are not whitelisted."))
end

local function kick(session, reason)
    if session.kicked || !current(session) then return end
    session.kicked = true
    session.queuedAt = nil
    if validPlayer(session.ply) then session.ply:Kick(reason) else game.KickID(session.data.networkid, reason) end
end

local function queue(session, delay)
    if !current(session) || session.kicked || (!session.joining && !gmInte.config.maintenance) then return end
    local due = SysTime() + (delay || 0)
    if !session.queuedAt then
        queueSequence = queueSequence + 1
        session.queueSequence = queueSequence
        session.queuedAt = due
    else
        session.queuedAt = math.min(session.queuedAt, due)
    end
end

local function validAccess(code, body, whitelist)
    return isnumber(code) && code >= 200 && code < 300 && istable(body) &&
        (!whitelist || (isbool(body.bypassMaintenance) && isbool(body.discordAdmin)))
end

local function startRequest(session)
    local request = { revision = session.revision, joining = session.joining, whitelist = gmInte.config.maintenance == true }
    session.request = request
    session.queuedAt = nil
    if !request.joining then activeOnline = activeOnline + 1 end
    local function complete(code, body, failed)
        -- A reconnect, policy update or role notification supersedes the old reply. Keep the
        -- actual work slot until completion, even when its answer is no longer authoritative.
        if session.request != request then return end
        session.request = nil
        if !request.joining then activeOnline = activeOnline - 1 end
        if current(session) && request.whitelist != (gmInte.config.maintenance == true) then queue(session) end
        if current(session) && request.revision == session.revision && request.whitelist == (gmInte.config.maintenance == true) &&
            (request.joining || onlineConfigReady) then
            local confirmed = !failed && validAccess(code, body, request.whitelist)
            if request.joining then
                session.joining = false
                if !localAdmin(session) then
                    if gmInte.config.maintenance && (!confirmed || (!body.bypassMaintenance && !body.discordAdmin)) then
                        kick(session, whitelistMessage())
                    elseif confirmed && gmInte.config.filterOnBan && body.ban then
                        kick(session, filterMessage(gmInte.getTranslation("filter.ban", "You are banned from this server.")))
                    elseif confirmed && gmInte.config.syncBan && body.discord_ban then
                        kick(session, filterMessage(gmInte.getTranslation("filter.discord_ban", "You are banned from our discord server.")))
                    end
                end
            elseif gmInte.config.maintenance && !localAdmin(session) then
                if confirmed then
                    if !body.bypassMaintenance && !body.discordAdmin then kick(session, whitelistMessage()) end
                else
                    -- A provider outage is not a denial for an already connected player.
                    queue(session, 10)
                end
            end
        end
        pump()
    end
    gmInte.api.get("/servers/:serverID/players/" .. session.steamID64 .. (request.whitelist && "/access" || ""),
        function(code, body) complete(code, body, false) end,
        function(code, body) complete(code, body, true) end)
end

pump = function()
    if pumping then return end
    pumping = true
    while true do
        local candidate
        for _, session in pairs(sessions) do
            if session.queuedAt && session.queuedAt <= SysTime() && !session.request && current(session) && !session.kicked &&
                (!session.joining || session.joinReady) &&
                (session.joining || (onlineConfigReady && gmInte.config.maintenance && gmInte.aprovedCredentials && activeOnline < 2)) &&
                (!candidate || session.queueSequence < candidate.queueSequence) then candidate = session end
        end
        if !candidate then break end
        if !candidate.joining && localAdmin(candidate) then candidate.queuedAt = nil else startRequest(candidate) end
    end
    pumping = false
end

local function readyJoin(session)
    if !current(session) || !session.spawned || !validPlayer(session.ply) then return end
    local rank = session.ply:GetUserGroup()
    if !isstring(rank) || rank == "" then return end
    session.joinReady = true
    queue(session)
    pump()
end

local function onlineSession(ply)
    if !validPlayer(ply) then return end
    local id = ply:SteamID64()
    if !steamID64(id) then return end
    local session = sessions[id]
    if !session || (session.ply && session.ply != ply) || (session.userID && session.userID != tostring(ply:UserID())) then
        session = { steamID64 = id, revision = 0 }
        sessions[id] = session
    end
    session.ply = ply
    session.userID = tostring(ply:UserID())
    return session
end

local function refresh(session)
    session.revision = session.revision + 1
    queue(session)
end

local function refreshAll()
    for _, ply in ipairs(player.GetAll()) do onlineSession(ply) end
    for _, session in pairs(sessions) do refresh(session) end
    pump()
end

function gmInte.wsRefreshPlayerAccess(data)
    if !istable(data) || (data.steamID != nil && !steamID64(data.steamID)) then return end
    if data.steamID == nil then refreshAll() return end
    local ply = player.GetBySteamID64(data.steamID)
    if validPlayer(ply) then onlineSession(ply) end
    local session = sessions[data.steamID]
    if session then refresh(session) pump() end
end

local function playerFilter(data)
    if !istable(data) || data.bot == 1 || data.bot == true || !isstring(data.networkid) then return end
    local id = util.SteamIDTo64(data.networkid)
    if !steamID64(id) then return end
    -- No positive-access cache: a new connection must observe the current Discord role.
    local session = { steamID64 = id, data = data, userID = data.userid != nil && tostring(data.userid) || nil, joining = true, revision = 0 }
    sessions[id] = session
    queue(session)
    pump()

    if gmInte.config.forcePlayerLink && gmInte.config.verifyOnJoin then
        local request = {}
        session.linkRequest = request
        local function complete(code, body, failed)
            if !current(session) || session.linkRequest != request then return end
            session.linkRequest = nil
            if !gmInte.config.forcePlayerLink || !gmInte.config.verifyOnJoin then return end
            if (!failed && istable(body) && !body.discordID) || (failed && code == 404) then
                kick(session, filterMessage(gmInte.getTranslation("filter.link", "You need to link your discord account before joining, verify your account on {1}", "https://gmod-integration.com/account")))
            end
        end
        gmInte.api.get("/users?steamID64=" .. id, function(code, body) complete(code, body, false) end,
            function(code, body) complete(code, body, true) end)
    end
end

gameevent.Listen("player_connect")
gameevent.Listen("player_disconnect")
hook.Add("player_connect", "gmInte:Player:Connect:Filter", playerFilter)
hook.Add("player_disconnect", "gmInte:Player:Disconnect:Filter", function(data)
    if !istable(data) || !isstring(data.networkid) then return end
    local id = util.SteamIDTo64(data.networkid)
    local session = sessions[id]
    if session && session.userID == tostring(data.userid) then sessions[id] = nil end
end)
hook.Add("PlayerInitialSpawn", "gmInte:Player:Spawn:Filter", function(ply)
    local session = onlineSession(ply)
    if !session then return end
    if !session.joining then queue(session) pump() return end
    -- player_connect has no usergroup. Wait until all spawn hooks can assign the real rank
    -- before requesting a decision that could deny an otherwise exempt administrator.
    timer.Simple(0, function()
        if !current(session) || session.ply != ply then return end
        session.spawned = true
        readyJoin(session)
    end)
end)
hook.Add("PlayerDisconnected", "gmInte:Player:DisconnectCleanup:Filter", function(ply)
    local id = ply:SteamID64()
    local session = sessions[id]
    if session && (session.ply == ply || session.userID == tostring(ply:UserID())) then sessions[id] = nil end
end)
local function waitForConfig()
    onlineConfigReady = false
    refreshAll()
end
hook.Add("GmodIntegration:Websocket:Ready", "gmInte:Player:RefreshAccess:Ready", waitForConfig)
hook.Add("GmodIntegration:Config:Synchronizing", "gmInte:Player:RefreshAccess:Synchronizing", waitForConfig)
hook.Add("GmodIntegration:Config:Synchronized", "gmInte:Player:RefreshAccess:Synchronized", function()
    onlineConfigReady = true
    refreshAll()
end)
hook.Add("GmodIntegration:Config:Changed", "gmInte:Player:RefreshAccess:Config", function(setting)
    if setting == "maintenance" || setting == "adminRank" then
        previousMaintenance = gmInte.config.maintenance
        refreshAll()
    end
end)
timer.Create("gmInte:Player:RefreshAccess", 1, 0, function()
    for _, session in pairs(sessions) do
        if session.joining && session.spawned && !session.joinReady then readyJoin(session) end
    end
    if previousMaintenance != gmInte.config.maintenance then
        previousMaintenance = gmInte.config.maintenance
        refreshAll()
    end
    if SysTime() - lastSweep >= 30 then
        lastSweep = SysTime()
        if gmInte.config.maintenance then
            for _, ply in ipairs(player.GetAll()) do
                local session = onlineSession(ply)
                if session && !session.request && !session.queuedAt then queue(session) end
            end
        end
    end
    pump()
end)
