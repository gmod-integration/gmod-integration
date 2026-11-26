-- Verification policy regressions run the actual server module with mocked engine and API calls.
local clock, hooks, timers, requests, messages, actors, playerMeta
local passed = 0

local function reset(options)
    options = options or {}
    clock, hooks, timers, requests, messages, actors = 1000, {}, {}, {}, {}, {}
    SERVER, CLIENT = true, false
    IsValid = function(value) return type(value) == "table" and value.valid == true end
    istable = function(value) return type(value) == "table" end
    isstring = function(value) return type(value) == "string" end
    RealTime = function() return clock end
    Color = function(r, g, b) return { r = r, g = g, b = b } end
    hook = {
        Add = function(event, id, callback)
            hooks[event] = hooks[event] or {}
            hooks[event][id] = callback
        end,
        Run = function(event, ...)
            for _, callback in pairs(hooks[event] or {}) do callback(...) end
        end,
    }
    timer = { Create = function(id, _, _, callback) timers[id] = callback end }
    player = { GetAll = function() return actors end }
    playerMeta = {}
    FindMetaTable = function() return playerMeta end
    gmInte = {
        config = {
            forcePlayerLink = options.force ~= false, verifyOnReadyKickTime = options.timeout or 600,
            verifyFamilySharing = false, clientBranch = options.branch or "any",
        },
        SendNet = function(id, data, ply) messages[#messages + 1] = { id = id, data = data, ply = ply } end,
        getTranslation = function(key, fallback, argument)
            return key .. ":" .. tostring(argument or fallback)
        end,
        api = { get = function(endpoint, success, failed)
            requests[#requests + 1] = { endpoint = endpoint, success = success, failed = failed }
        end },
    }
    loadGLua("lua/gmod_integration/core/utils/sh_player_meta.lua")
    loadGLua("lua/gmod_integration/modules/players_filter_link_account/sh_main.lua")
    loadGLua("lua/gmod_integration/modules/players_filter_link_account/sv_players_verif.lua")
end

local function actor(id, branch)
    local ply = setmetatable({ valid = true, branch = branch or "x86-64", freezes = {}, kicks = {} }, { __index = playerMeta })
    function ply:IsPlayer() return self.isPlayer ~= false end
    function ply:IsBot() return false end
    function ply:SteamID64() return id or "76561198000000001" end
    function ply:Freeze(frozen) self.frozen = frozen; self.freezes[#self.freezes + 1] = frozen end
    function ply:Kick(reason) self.kicks[#self.kicks + 1] = reason end
    actors[#actors + 1] = ply
    return ply
end

local function ready(ply)
    hook.Run("gmInte:PlayerReady", ply)
end

local function tick(seconds, branch)
    clock = clock + seconds
    timers[branch and "gmInte:Verif:Check:forcePlayerBranch" or "gmInte:Verif:Check:forcePlayerLink"]()
end

local function test(name, callback)
    reset()
    local ok, problem = pcall(callback)
    assert(ok, name .. ": " .. tostring(problem))
    passed = passed + 1
end

test("an unlinked player remains queued across reminders and is kicked at the real deadline", function()
    local ply = actor()
    ready(ply)
    assert(ply.frozen and #requests == 1)
    assert(requests[1].endpoint == "/users?steamID64=" .. ply:SteamID64())
    requests[1].success(200, {})
    tick(30)
    assert(gmInte.plyInVerifQueue[ply:SteamID64()] == ply and #ply.kicks == 0)
    tick(30)
    assert(gmInte.plyInVerifQueue[ply:SteamID64()] == ply and #ply.kicks == 0)
    tick(540)
    assert(#ply.kicks == 1 and gmInte.plyInVerifQueue[ply:SteamID64()] == nil)
    tick(30)
    assert(#ply.kicks == 1)
end)

test("successful verification clears the queue and prevents later kicks", function()
    local ply = actor()
    ready(ply)
    requests[1].success(200, { discordID = "1051881514020917408" })
    assert(ply:gmIntIsVerified() and not ply.frozen and gmInte.plyInVerifQueue[ply:SteamID64()] == nil)
    tick(1000)
    assert(#ply.kicks == 0)
end)

test("a repeated ready or refresh cannot queue overlapping lookups", function()
    local ply = actor()
    ready(ply)
    gmInte.verifyPlayer(ply)
    ready(ply)
    assert(#requests == 1)
    requests[1].success(200, {})
    tick(590)
    gmInte.verifyPlayer(ply)
    assert(#requests == 2)
    requests[2].success(200, {})
    tick(10)
    assert(#ply.kicks == 1)
end)

test("a zero kick timeout retains the verification block without kicking", function()
    reset({ timeout = 0 })
    local ply = actor()
    ready(ply)
    requests[1].failed(404, {})
    tick(100000)
    assert(ply.frozen and #ply.kicks == 0 and gmInte.plyInVerifQueue[ply:SteamID64()] == ply)
end)

test("failed or malformed lookups cannot preserve a formerly verified state", function()
    for _, value in ipairs({ false, 42, {}, { discordID = "" }, { discordID = 123 } }) do
        reset()
        local ply = actor()
        ply.gmIntVerified = true
        ready(ply)
        requests[1].success(200, value)
        assert(not ply:gmIntIsVerified() and ply.frozen)
        assert(gmInte.plyInVerifQueue[ply:SteamID64()] == ply)
    end
end)

test("disabling verification during lookup releases the player and ignores duplicate callbacks", function()
    local ply = actor()
    ready(ply)
    gmInte.config.forcePlayerLink = false
    requests[1].failed(503, {})
    assert(not ply.frozen and gmInte.plyInVerifQueue[ply:SteamID64()] == nil)
    local sent = #messages
    requests[1].success(200, {})
    assert(#messages == sent and not ply.frozen)
end)

test("the maintenance timer releases disabled checks and cancels outstanding callbacks", function()
    local ply = actor()
    ready(ply)
    gmInte.config.forcePlayerLink = false
    tick(30)
    assert(not ply.frozen and gmInte.plyInVerifQueue[ply:SteamID64()] == nil)
    local sent = #messages
    requests[1].failed(503, {})
    assert(not ply.frozen and #messages == sent)
end)

test("enabling force verification also checks players who are already ready", function()
    reset({ force = false })
    local ply = actor()
    ready(ply)
    assert(#requests == 0)
    gmInte.config.forcePlayerLink = true
    tick(30)
    assert(#requests == 1 and ply.frozen and gmInte.plyInVerifQueue[ply:SteamID64()] == ply)
end)

test("disconnect cleanup removes both queues and cancels late responses", function()
    reset({ branch = "dev" })
    local ply = actor()
    ready(ply)
    assert(gmInte.plyInVerifQueue[ply:SteamID64()] == ply and gmInte.plyInVerifBranchQueue[ply:SteamID64()] == ply)
    ply.valid = false
    hook.Run("PlayerDisconnected", ply)
    assert(gmInte.plyInVerifQueue[ply:SteamID64()] == nil and gmInte.plyInVerifBranchQueue[ply:SteamID64()] == nil)
    local sent = #messages
    requests[1].success(200, { discordID = "1051881514020917408" })
    assert(#messages == sent)
end)

test("invalid, non-player and not-ready requests stay inert", function()
    gmInte.verifyPlayer(nil)
    local ply = actor()
    gmInte.verifyPlayer(ply)
    ply.gmIntIsReady = true
    ply.isPlayer = false
    gmInte.verifyPlayer(ply)
    ply.isPlayer, ply.valid = true, false
    gmInte.verifyPlayer(ply)
    assert(#requests == 0 and #ply.freezes == 0)
end)

test("a late response for an old player entity cannot clear its replacement's queue", function()
    local old = actor()
    ready(old)
    local replacement = actor()
    ready(replacement)
    requests[1].success(200, { discordID = "1051881514020917408" })
    assert(gmInte.plyInVerifQueue[replacement:SteamID64()] == replacement and replacement.frozen)
end)

test("correct branches do not block linked players or release a pending account verification", function()
    reset({ branch = "x86-64" })
    local ply = actor()
    ready(ply)
    assert(ply.frozen and gmInte.plyInVerifBranchQueue[ply:SteamID64()] == nil)
    requests[1].success(200, { discordID = "1051881514020917408" })
    assert(not ply.frozen)
end)

test("account verification success cannot bypass a wrong-branch block", function()
    reset({ branch = "dev" })
    local ply = actor()
    ready(ply)
    requests[1].success(200, { discordID = "1051881514020917408" })
    assert(ply.frozen and gmInte.plyInVerifBranchQueue[ply:SteamID64()] == ply)
    gmInte.config.clientBranch = "any"
    tick(30, true)
    assert(not ply.frozen and gmInte.plyInVerifBranchQueue[ply:SteamID64()] == nil)
end)

test("an inherited queue entry gets a stable deadline instead of a new clock on every reminder", function()
    local ply = actor()
    ply.gmIntIsReady = true
    gmInte.plyInVerifQueue[ply:SteamID64()] = ply
    tick(30)
    tick(600)
    assert(#ply.kicks == 1)
end)

test("the initial sweep recovers already-ready players missed by the old queue", function()
    local ply = actor()
    ply.gmIntIsReady, ply.frozen = true, true
    tick(30)
    assert(#requests == 1 and gmInte.plyInVerifQueue[ply:SteamID64()] == ply)
    requests[1].success(200, {})
    tick(600)
    assert(#ply.kicks == 1)
end)

print("Verification regressions: " .. passed .. " passed")
