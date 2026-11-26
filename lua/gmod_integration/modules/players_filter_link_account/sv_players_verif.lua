gmInte.plyInVerifQueue = gmInte.plyInVerifQueue || {}
gmInte.plyInVerifBranchQueue = gmInte.plyInVerifBranchQueue || {}
local requests = setmetatable({}, { __mode = "k" })
local started = setmetatable({}, { __mode = "k" })
local branchStarted = setmetatable({}, { __mode = "k" })
local previousForceLink = gmInte.config.forcePlayerLink
local firstSweep = true

local function validPlayer(ply)
    return IsValid(ply) && ply:IsPlayer()
end

local function requiresBranch(ply)
    return gmInte.config.clientBranch != "any" && ply:gmInteGetBranch() != gmInte.config.clientBranch
end

local function releaseVerification(ply)
    if gmInte.plyInVerifQueue[ply:SteamID64()] == ply then gmInte.plyInVerifQueue[ply:SteamID64()] = nil end
    started[ply] = nil
    if !requiresBranch(ply) then ply:Freeze(false) end
end

local function sendVerificationMessage(ply, key, fallback, color)
    gmInte.SendNet("chatColorMessage", {
        [1] = { text = gmInte.getTranslation(key, fallback), color = color }
    }, ply)
end

function gmInte.verifyPlayer(ply)
    if !validPlayer(ply) || !ply.gmIntIsReady || !gmInte.config.forcePlayerLink || requests[ply] then return end
    local steamID64 = ply:SteamID64()
    local request = {}
    requests[ply] = request
    started[ply] = started[ply] || RealTime()
    gmInte.plyInVerifQueue[steamID64] = ply
    ply.gmIntVerified = false
    ply:Freeze(true)
    local function complete(data, failed)
        if requests[ply] != request then return end
        requests[ply] = nil
        if !validPlayer(ply) || gmInte.plyInVerifQueue[steamID64] != ply then return end
        if !gmInte.config.forcePlayerLink then releaseVerification(ply) return end
        if !ply.gmIntIsReady then return end
        ply.gmIntVerified = !failed && istable(data) && isstring(data.discordID) && data.discordID != "" || false
        if ply.gmIntVerified then
            releaseVerification(ply)
            sendVerificationMessage(ply, "verification.success", "You have been verified", Color(255, 255, 255))
        else
            gmInte.plyInVerifQueue[steamID64] = ply
            ply:Freeze(true)
            if failed then
                sendVerificationMessage(ply, "verification.link_require", "This server requires you to link your Discord account to play", Color(255, 0, 0))
            else
                sendVerificationMessage(ply, "verification.fail", "Failed to verify you", Color(255, 0, 0))
            end
            gmInte.SendNet("openVerifPopup", nil, ply)
        end
    end
    gmInte.api.get("/users?steamID64=" .. steamID64, function(_, data) complete(data, false) end,
        function() complete(nil, true) end)
end

function gmInte.verifyPlayerBranch(ply)
    if !validPlayer(ply) then return end
    local steamID64 = ply:SteamID64()
    if !requiresBranch(ply) then
        gmInte.plyInVerifBranchQueue[steamID64] = nil
        branchStarted[ply] = nil
        if gmInte.plyInVerifQueue[steamID64] != ply then ply:Freeze(false) end
        return
    end
    ply:Freeze(true)
    branchStarted[ply] = branchStarted[ply] || RealTime()
    gmInte.plyInVerifBranchQueue[steamID64] = ply
end

function gmInte.blockFamilySharing(ply)
    if !gmInte.config.verifyFamilySharing then return end
    if !validPlayer(ply) || ply:IsBot() || !ply:IsFullyAuthenticated() then return end
    if ply:OwnerSteamID64() == ply:SteamID64() then return end
    ply:Kick(gmInte.getTranslation("verification.family_sharing", "This server does not allow family sharing"))
end

hook.Add("gmInte:PlayerReady", "gmInte:Verif:PlayerReady", function(ply)
    if !validPlayer(ply) then return end
    ply.gmIntIsReady = true
    gmInte.verifyPlayer(ply)
    gmInte.verifyPlayerBranch(ply)
    gmInte.blockFamilySharing(ply)
end)

-- Keep unverified players queued until success, disconnect or the actual deadline.
timer.Create("gmInte:Verif:Check:forcePlayerLink", 30, 0, function()
    if gmInte.config.forcePlayerLink && (!previousForceLink || firstSweep) then
        for _, ply in ipairs(player.GetAll()) do
            if validPlayer(ply) && ply.gmIntIsReady && (!previousForceLink ||
                (!ply:gmIntIsVerified() && gmInte.plyInVerifQueue[ply:SteamID64()] != ply)) then
                gmInte.verifyPlayer(ply)
            end
        end
    end
    firstSweep = false
    previousForceLink = gmInte.config.forcePlayerLink
    local timeout = tonumber(gmInte.config.verifyOnReadyKickTime) || 600
    for steamID64, ply in pairs(gmInte.plyInVerifQueue) do
        if !validPlayer(ply) then
            gmInte.plyInVerifQueue[steamID64] = nil
            requests[ply], started[ply] = nil, nil
        elseif !gmInte.config.forcePlayerLink || ply:gmIntIsVerified() then
            requests[ply] = nil
            releaseVerification(ply)
        elseif timeout > 0 then
            started[ply] = started[ply] || RealTime()
            local elapsed = RealTime() - started[ply]
            local remaining = math.max(0, math.ceil(timeout - elapsed))
            if elapsed >= timeout then
                requests[ply], started[ply] = nil, nil
                gmInte.plyInVerifQueue[steamID64] = nil
                ply:Kick(gmInte.getTranslation("verification.kick", "You have been kicked for not verifying, verify your account on {1}", "https://gmod-integration.com/account"))
            else
                gmInte.SendNet("chatColorMessage", {
                    [1] = { text = gmInte.getTranslation("verification.kick_in", "If you don't verify in {1} seconds you will be kicked", remaining), color = Color(224, 89, 89) }
                }, ply)
            end
        end
    end
end)

timer.Create("gmInte:Verif:Check:forcePlayerBranch", 30, 0, function()
    local timeout = tonumber(gmInte.config.verifyOnReadyKickTime) || 600
    if timeout == 0 then timeout = 600 end
    for steamID64, ply in pairs(gmInte.plyInVerifBranchQueue) do
        if !validPlayer(ply) then
            gmInte.plyInVerifBranchQueue[steamID64] = nil
            branchStarted[ply] = nil
        elseif !requiresBranch(ply) then
            gmInte.verifyPlayerBranch(ply)
        else
            branchStarted[ply] = branchStarted[ply] || RealTime()
            local elapsed = RealTime() - branchStarted[ply]
            if elapsed >= timeout then
                gmInte.plyInVerifBranchQueue[steamID64] = nil
                branchStarted[ply] = nil
                ply:Kick(gmInte.getTranslation("verification.kick_branch", "You have been kicked for not changing your branch to {1}", gmInte.config.clientBranch))
            else
                gmInte.SendNet("chatColorMessage", {
                    [1] = { text = gmInte.getTranslation("verification.kick_in_branch", "If you don't change your branch in {1} seconds you will be kicked", math.max(0, math.ceil(timeout - elapsed))), color = Color(224, 89, 89) }
                }, ply)
            end
        end
    end
end)

hook.Add("PlayerDisconnected", "gmInte:Verif:DisconnectCleanup", function(ply)
    requests[ply], started[ply], branchStarted[ply] = nil, nil, nil
    for steamID64, queued in pairs(gmInte.plyInVerifQueue) do
        if queued == ply then gmInte.plyInVerifQueue[steamID64] = nil end
    end
    for steamID64, queued in pairs(gmInte.plyInVerifBranchQueue) do
        if queued == ply then gmInte.plyInVerifBranchQueue[steamID64] = nil end
    end
end)
