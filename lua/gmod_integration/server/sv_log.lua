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

local function logFormatPlayer(ply, data)
    data = data or {}
    data.steamID64 = ply:SteamID64()
    data.steamID = ply:SteamID()
    data.nick = ply:Nick()
    data.userGroup = ply:GetUserGroup()
    data.team = logFormatTeam(ply:Team())
    return data
end

local function logDisable()
    return gmInte.config.disableLog
end

//
// Posts
//

function gmInte.postLogPlayerSay(ply, text, teamChat)
    if (logDisable() || ply:IsBot()) then return end

    gmInte.post("/server/log/playerSay",
        {
            ["ply"] = logFormatPlayer(ply),
            ["text"] = text,
            ["teamChat"] = teamChat
        }
    )
end

function gmInte.postLogPlayerDeath(ply, inflictor, attacker)
    if (logDisable() || ply:IsBot() || attacker:IsBot()) then return end

    gmInte.post("/server/log/playerDeath",
        {
            ["ply"] = logFormatPlayer(ply),
            ["inflictor"] = logFormatEntity(inflictor),
            ["attacker"] = logFormatPlayer(attacker)
        }
    )
end

function gmInte.postLogPlayerInitialSpawn(ply)
    if (logDisable() || ply:IsBot()) then return end

    gmInte.post("/server/log/playerInitialSpawn",
        {
            ["ply"] = logFormatPlayer(ply)
        }
    )
end

function gmInte.postLogPlayerHurt(ply, attacker, healthRemaining, damageTaken)
    if (logDisable() || ply:IsBot() || attacker:IsBot()) then return end

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

        gmInte.post("/server/log/playerHurt",
            {
                ["ply"] = logFormatPlayer(ply),
                ["attacker"] = logFormatPlayer(attacker),
                ["healthRemaining"] = healthRemaining,
                ["damageTaken"] = ply.gmodInteTotalDamage
            }
        )
    end)
end

function gmInte.postLogPlayerSpawnedSomething(object, ply, ent, model)
    if (logDisable() || ply:IsBot()) then return end

    gmInte.post("/server/log/playerSpawnedSomething",
        {
            ["object"] = object,
            ["ply"] = logFormatPlayer(ply),
            ["ent"] = logFormatEntity(ent),
            ["model"] = model || ""
        }
    )
end

function gmInte.postLogPlayerSpawn(ply)
    if (logDisable() || ply:IsBot()) then return end

    gmInte.post("/server/log/playerSpawn",
        {
            ["ply"] = logFormatPlayer(ply)
        }
    )
end

function gmInte.postLogPlayerDisconnect(ply)
    if (logDisable() || ply:IsBot()) then return end

    gmInte.post("/server/log/playerDisconnect",
        {
            ["ply"] = logFormatPlayer(ply)
        }
    )
end

function gmInte.postLogPlayerConnect(data)
    if (logDisable() || data.bot) then return end

    gmInte.post("/server/log/playerConnect",
        {
            ["steamID64"] = util.SteamIDTo64(data.networkid),
            ["steamID"] = data.networkid,
            ["name"] = data.name,
            ["ip"] = data.address
        }
    )
end

//
// Hooks
//

gameevent.Listen("player_connect")

// Sandbox - Player
hook.Add("PlayerSay", "gmInte:Log:PlayerSay", function(ply, text, teamChat)
    gmInte.postLogPlayerSay(ply, text, teamChat)
end)
hook.Add("PlayerSpawn", "gmInte:Log:PlayerSpawn", function(ply)
    gmInte.postLogPlayerSpawn(ply)
end)
hook.Add("PlayerInitialSpawn", "gmInte:Log:PlayerInitialSpawn", function(ply)
    gmInte.postLogPlayerInitialSpawn(ply)
end)
hook.Add("PlayerDisconnected", "gmInte:Log:PlayerDisconnected", function(ply)
    gmInte.postLogPlayerDisconnect(ply)
end)

// Sandbox - Server Events
hook.Add("player_connect", "gmInte:Log:PlayerConnect", function(data)
    gmInte.postLogPlayerConnect(data)
end)

// Sandbox - Player Combat
hook.Add("PlayerDeath", "gmInte:Log:PlayerDeath", function(ply, inflictor, attacker)
    gmInte.postLogPlayerDeath(ply, inflictor, attacker)
end)
hook.Add("PlayerHurt", "gmInte:Log:PlayerHurt", function(ply, attacker, healthRemaining, damageTaken)
    gmInte.postLogPlayerHurt(ply, attacker, healthRemaining, damageTaken)
end)

// Sandbox - Spawnables
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