function gmInte.wsPlayerSay(data)
    gmInte.SendNet("wsRelayDiscordChat", data, nil)
end

local nextRelayWarningAt = 0
local function reportRelayFailure(status)
    if CurTime() < nextRelayWarningAt then return end
    nextRelayWarningAt = CurTime() + 60
    local message = gmInte.getTranslation("chat.relay_failed", "The chat relay could not confirm delivery to Discord. Check the server console and relay configuration.")
    local detail = isnumber(status) && status >= 100 && status <= 599 && status % 1 == 0 && (" (" .. tostring(status) .. ")") || ""
    gmInte.logWarning(message .. detail)
    for _, admin in ipairs(player.GetAll()) do
        if IsValid(admin) && admin:IsPlayer() && admin:gmIntIsAdmin() then
            gmInte.SendNet("chatColorMessage", { { text = message, color = Color(228, 81, 81) } }, admin)
        end
    end
end

function gmInte.playerSay(ply, text, teamOnly)
    return gmInte.api.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/say", {
        ["player"] = gmInte.getPlayerFormat(ply),
        ["text"] = text,
        ["teamOnly"] = teamOnly,
    }, nil, reportRelayFailure)
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
