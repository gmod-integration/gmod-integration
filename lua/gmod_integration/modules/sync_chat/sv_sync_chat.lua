function gmInte.wsPlayerSay(data)
    gmInte.SendNet("wsRelayDiscordChat", data, nil)
end

function gmInte.playerSay(ply, text, teamOnly)
    gmInte.http.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/say", {
        ["player"] = gmInte.getPlayerFormat(ply),
        ["text"] = text,
        ["teamOnly"] = teamOnly,
    })
end

local function isSAMAsayCommand(text)
    if !SAM_LOADED || !sam || !sam.command || !sam.command.get_command("asay") then return false end

    text = string.Trim(text)
    if string.StartWith(text, "@") then return true end

    return string.lower(text) == "!asay" || string.match(string.lower(text), "^!asay%s") != nil
end

hook.Add("PlayerSay", "gmInte:SyncChat:PlayerSay", function(ply, text, team)
    -- The wrapped SAM command relays the final content instead of the command itself.
    if isSAMAsayCommand(text) then return end

    gmInte.playerSay(ply, text, team)
end)

local function wrapSAMAsayCommand(command)
    if !command || command.gmInteSyncChatWrapped || !isfunction(command.on_execute) then return end

    local onExecute = command.on_execute
    command.gmInteSyncChatWrapped = true

    command.on_execute = function(ply, text)
        local shouldRelay = IsValid(ply) && isstring(text) && text != ""
        local relayText = text
        local reportsEnabled = sam.config.get("Reports", true)

        if shouldRelay && reportsEnabled && !ply:HasPermission("see_admin_chat") then
            local cooldowns = ply.sam_cool_downs
            local reportCooldown = cooldowns && cooldowns.NewReport
            shouldRelay = !reportCooldown || reportCooldown <= SysTime()
            relayText = string.sub(text, 1, 120)
        end

        local result = onExecute(ply, text)

        if shouldRelay then
            gmInte.playerSay(ply, relayText, false)
        end

        return result
    end
end

hook.Add("SAM.CommandAdded", "gmInte:SyncChat:WrapSAMAsay", function(name, command)
    if name == "asay" then
        wrapSAMAsayCommand(command)
    end
end)

-- Also supports a hot reload of Gmod Integration after SAM has already loaded.
timer.Simple(0, function()
    if sam && sam.command then
        wrapSAMAsayCommand(sam.command.get_command("asay"))
    end
end)
