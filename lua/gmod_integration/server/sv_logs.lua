//
// Functions
//

local function logFormatWeapon(weapon, data)
    data = data or {}
    data.class = weapon:GetClass()
    data.printName = weapon:GetPrintName()
    return data
end

local function logFormatEntity(ent, data)
    data = data or {}
    data.class = ent:GetClass()
    data.model = ent:GetModel()
    data.pos = ent:GetPos()
    data.ang = ent:GetAngles()
    return data
end

local function logFormatVector(vec, data)
    data = data or {}
    data.x = vec.x
    data.y = vec.y
    data.z = vec.z
    return data
end

local function logFormatAngle(ang, data)
    data = data or {}
    data.p = ang.p
    data.y = ang.y
    data.r = ang.r
    return data
end

local function logFormatTeam(teamID, data)
    data = data or {}
    data.id = teamID
    data.name = team.GetName(teamID)
    return data
end

local function logDisable()
    return !gmInte.config.sendLog
end

local function validLogAndPlayers(players)
    if (logDisable()) then return false end
    for _, ply in pairs(players) do
        // return if not valid, player or bot and bots logs are disabled
        if (!IsValid(ply)) then return false end
        if (!ply:IsPlayer()) then return false end
        if (!ply:IsBot() && !gmInte.config.logBotActions) then return false end
    end
    return true
end

//
// Posts
//

function gmInte.postLogPlayerSay(ply, text, teamChat)
    if (!validLogAndPlayers({ply})) then return end

    gmInte.http.post("/logs/playerSay",
        {
            ["ply"] = gmInte.playerFormat(ply),
            ["text"] = text,
            ["teamChat"] = teamChat
        }
    )
end

function gmInte.postLogPlayerDeath(ply, inflictor, attacker)
    if (!validLogAndPlayers({ply, attacker})) then return end

    gmInte.http.post("/logs/playerDeath",
        {
            ["ply"] = gmInte.playerFormat(ply),
            ["inflictor"] = logFormatEntity(inflictor),
            ["attacker"] = gmInte.playerFormat(attacker)
        }
    )
end

function gmInte.postLogPlayerInitialSpawn(ply)
    if (!validLogAndPlayers({ply})) then return end

    gmInte.http.post("/logs/playerInitialSpawn",
        {
            ["ply"] = gmInte.playerFormat(ply)
        }
    )
end

function gmInte.postLogPlayerHurt(ply, attacker, healthRemaining, damageTaken)
    if (!validLogAndPlayers({ply, attacker})) then return end

    // Wait a second to see if the player is going to be hurt again
    ply.gmodInteLastHurt = ply.gmodInteLastHurt || {}
    local locCurTime = CurTime()
    ply.gmodInteLastHurt[attacker:SteamID64()] = locCurTime

    timer.Simple(1, function()
        if (ply.gmodInteLastHurt[attacker:SteamID64()] != locCurTime) then
            ply.gmodInteTotalDamage = ply.gmodInteTotalDamage || 0
            ply.gmodInteTotalDamage = ply.gmodInteTotalDamage + damageTaken
            return
        end

        gmInte.http.post("/logs/playerHurt",
            {
                ["ply"] = gmInte.playerFormat(ply),
                ["attacker"] = gmInte.playerFormat(attacker),
                ["healthRemaining"] = healthRemaining,
                ["damageTaken"] = ply.gmodInteTotalDamage
            }
        )
    end)
end

function gmInte.postLogPlayerSpawnedSomething(object, ply, ent, model)
    if (!validLogAndPlayers({ply})) then return end

    gmInte.http.post("/logs/playerSpawnedSomething",
        {
            ["object"] = object,
            ["ply"] = gmInte.playerFormat(ply),
            ["ent"] = logFormatEntity(ent),
            ["model"] = model || ""
        }
    )
end

function gmInte.postLogPlayerSpawn(ply)
    if (!validLogAndPlayers({ply})) then return end

    gmInte.http.post("/logs/playerSpawn",
        {
            ["ply"] = gmInte.playerFormat(ply)
        }
    )
end

function gmInte.postLogPlayerDisconnect(ply)
    if (!validLogAndPlayers({ply})) then return end

    gmInte.http.post("/logs/playerDisconnect",
        {
            ["ply"] = gmInte.playerFormat(ply)
        }
    )
end

function gmInte.postLogPlayerConnect(data)
    if (logDisable() || data.bot) then return end

    gmInte.http.post("/logs/playerConnect",
        {
            ["steamID64"] = util.SteamIDTo64(data.networkid),
            ["steamID"] = data.networkid,
            ["name"] = data.name,
            ["ip"] = data.address
        }
    )
end

function gmInte.postLogPlayerGivet(ply, class, swep)
    if (!validLogAndPlayers({ply})) then return end

    gmInte.http.post("/logs/playerGive",
        {
            ["ply"] = gmInte.playerFormat(ply),
            ["class"] = class,
            ["swep"] = swep
        }
    )
end

//
// Hooks
//

gameevent.Listen("player_connect")

// Base - Player
hook.Add("PlayerSay", "gmInte:Log:PlayerSay", function(ply, text, teamChat)
    gmInte.postLogPlayerSay(ply, text, teamChat)
end)
hook.Add("PlayerSpawn", "gmInte:Log:PlayerSpawn", function(ply)
    gmInte.postLogPlayerSpawn(ply)
end)
hook.Add("player_connect", "gmInte:Log:PlayerConnect", function(data)
    gmInte.postLogPlayerConnect(data)
end)
hook.Add("PlayerInitialSpawn", "gmInte:Log:PlayerInitialSpawn", function(ply)
    gmInte.postLogPlayerInitialSpawn(ply)
end)
hook.Add("PlayerDisconnected", "gmInte:Log:PlayerDisconnected", function(ply)
    gmInte.postLogPlayerDisconnect(ply)
end)
hook.Add("PlayerGiveSWEP", "gmInte:Log:PlayerSWEPs", function( ply, class, swep )
    gmInte.postLogPlayerGivet(ply, class, swep)
end)

// Base - Player Combat
hook.Add("PlayerDeath", "gmInte:Log:PlayerDeath", function(ply, inflictor, attacker)
    gmInte.postLogPlayerDeath(ply, inflictor, attacker)
end)
hook.Add("PlayerHurt", "gmInte:Log:PlayerHurt", function(ply, attacker, healthRemaining, damageTaken)
    gmInte.postLogPlayerHurt(ply, attacker, healthRemaining, damageTaken)
end)

// Base - Spawnables
hook.Add("PlayerSpawnedProp", "gmInte:Log:PlayerSpawnedProp", function(ply, model, ent)
    gmInte.postLogPlayerSpawnedSomething("SENT", ply, ent, model)
end)
hook.Add("PlayerSpawnedSENT", "gmInte:Log:PlayerSpawnedSENT", function(ply, ent)
    gmInte.postLogPlayerSpawnedSomething("SENT", ply, ent)
end)
hook.Add("PlayerSpawnedNPC", "gmInte:Log:PlayerSpawnedNPC", function(ply, ent)
    gmInte.postLogPlayerSpawnedSomething("NPC", ply, ent)
end)
hook.Add("PlayerSpawnedVehicle", "gmInte:Log:PlayerSpawnedVehicle", function(ply, ent)
    gmInte.postLogPlayerSpawnedSomething("Vehicle", ply, ent)
end)
hook.Add("PlayerSpawnedEffect", "gmInte:Log:PlayerSpawnedEffect", function(ply, model, ent)
    gmInte.postLogPlayerSpawnedSomething("Effect", ply, ent, model)
end)
hook.Add("PlayerSpawnedRagdoll", "gmInte:Log:PlayerSpawnedRagdoll", function(ply, model, ent)
    gmInte.postLogPlayerSpawnedSomething("Ragdoll", ply, ent, model)
end)
hook.Add("PlayerSpawnedSWEP", "gmInte:Log:PlayerSpawnedSWEP", function(ply, ent)
    gmInte.postLogPlayerSpawnedSomething("SWEP", ply, ent)
end)