function gmInte.playerReady(ply)
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    // Initialize Time
    ply.gmIntTimeConnect = math.Round(RealTime())
    // Send Public Config
    gmInte.publicGetConfig(ply)
    gmInte.http.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/ready", {
        ["player"] = gmInte.getPlayerFormat(ply)
    })
end

function gmInte.playerConnect(data)
    data.steamID64 = util.SteamIDTo64(data.networkid)
    gmInte.http.post("/servers/:serverID/players/" .. util.SteamIDTo64(data.networkid) .. "/connect", data)
end

function gmInte.playerDisconnected(ply)
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    gmInte.http.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/disconnect", {
        ["player"] = gmInte.getPlayerFormat(ply),
    })
end

function gmInte.playerSpawn(ply)
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    gmInte.http.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/spawn", {
        ["player"] = gmInte.getPlayerFormat(ply)
    })
end

function gmInte.playerDeath(ply, inflictor, attacker)
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    if !attacker:IsValid() || !attacker:IsPlayer(attacker) then return end
    if !inflictor:IsValid() then return end
    gmInte.http.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/death", {
        ["player"] = gmInte.getPlayerFormat(ply),
        ["inflictor"] = gmInte.getEntityFormat(inflictor),
        ["attacker"] = gmInte.getPlayerFormat(attacker)
    })
end

function gmInte.playerInitialSpawn(ply)
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    gmInte.http.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/initial-spawn", {
        ["player"] = gmInte.getPlayerFormat(ply)
    })
end

function gmInte.postLogPlayerHurt(ply, attacker, healthRemaining, damageTaken)
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    if !attacker:IsValid() || !attacker:IsPlayer(attacker) then return end
    // Wait a second to see if the player is going to be hurt again
    ply.gmodInteLastHurt = ply.gmodInteLastHurt || {}
    local locCurTime = CurTime()
    ply.gmodInteLastHurt[attacker:SteamID64()] = locCurTime
    timer.Simple(1, function()
        if ply.gmodInteLastHurt[attacker:SteamID64()] != locCurTime then
            ply.gmodInteTotalDamage = ply.gmodInteTotalDamage || 0
            ply.gmodInteTotalDamage = ply.gmodInteTotalDamage + damageTaken
            return
        end

        gmInte.http.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/hurt", {
            ["victim"] = gmInte.getPlayerFormat(ply),
            ["attacker"] = gmInte.getPlayerFormat(attacker),
            ["healthRemaining"] = math.Round(healthRemaining),
            ["damageTaken"] = math.Round(damageTaken)
        })
    end)
end

function gmInte.postLogPlayerSpawnedSomething(object, ply, ent, model)
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    if !ent:IsValid() then return end
    gmInte.http.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/spawn/" .. object, {
        ["player"] = gmInte.getPlayerFormat(ply),
        ["entity"] = gmInte.getEntityFormat(ent),
        ["model"] = model || ""
    })
end

function gmInte.postLogPlayerGive(ply, class, swep)
    if !ply:IsValid() || !ply:IsPlayer(ply) then return end
    gmInte.http.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/give", {
        ["player"] = gmInte.getPlayerFormat(ply),
        ["class"] = class,
        ["swep"] = swep
    })
end

hook.Add("gmInte:PlayerReady", "gmInte:Player:Ready", function(ply) gmInte.playerReady(ply) end)
hook.Add("ShutDown", "gmInte:Server:Shutdown:SavePlayers", function()
    for _, ply in pairs(player.GetAll()) do
        gmInte.playerDisconnected(ply)
    end
end)

gameevent.Listen("player_connect")
hook.Add("player_connect", "gmInte:Player:Connect", function(data) gmInte.playerConnect(data) end)
hook.Add("PlayerDisconnected", "gmInte:Player:Disconnect", function(ply) gmInte.playerDisconnected(ply) end)
hook.Add("PlayerSpawn", "gmInte:Player:Spawn", function(ply) gmInte.playerSpawn(ply) end)
hook.Add("PlayerInitialSpawn", "gmInte:Player:InitialSpawn", function(ply) gmInte.playerInitialSpawn(ply) end)
hook.Add("PlayerGiveSWEP", "gmInte:Player:SWEPs", function(ply, class, swep) gmInte.postLogPlayerGive(ply, class, swep) end)
hook.Add("PlayerDeath", "gmInte:Player:Death", function(ply, inflictor, attacker) gmInte.playerDeath(ply, inflictor, attacker) end)
hook.Add("PlayerHurt", "gmInte:Player:Hurt", function(ply, attacker, healthRemaining, damageTaken) gmInte.postLogPlayerHurt(ply, attacker, healthRemaining, damageTaken) end)
hook.Add("PlayerSpawnedProp", "gmInte:Player:SpawnedProp", function(ply, model, ent) gmInte.postLogPlayerSpawnedSomething("prop", ply, ent, model) end)
hook.Add("PlayerSpawnedSENT", "gmInte:Player:SpawnedSENT", function(ply, ent) gmInte.postLogPlayerSpawnedSomething("sent", ply, ent) end)
hook.Add("PlayerSpawnedNPC", "gmInte:Player:SpawnedNPC", function(ply, ent) gmInte.postLogPlayerSpawnedSomething("npc", ply, ent) end)
hook.Add("PlayerSpawnedVehicle", "gmInte:Player:SpawnedVehicle", function(ply, ent) gmInte.postLogPlayerSpawnedSomething("vehicle", ply, ent) end)
hook.Add("PlayerSpawnedEffect", "gmInte:Player:SpawnedEffect", function(ply, model, ent) gmInte.postLogPlayerSpawnedSomething("effect", ply, ent, model) end)
hook.Add("PlayerSpawnedRagdoll", "gmInte:Player:SpawnedRagdoll", function(ply, model, ent) gmInte.postLogPlayerSpawnedSomething("ragdoll", ply, ent, model) end)
hook.Add("PlayerSpawnedSWEP", "gmInte:Player:SpawnedSWEP", function(ply, ent) gmInte.postLogPlayerSpawnedSomething("swep", ply, ent) end)