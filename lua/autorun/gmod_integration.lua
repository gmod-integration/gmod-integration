if game.SinglePlayer() then return print("Gmod Integration is not supported in Singleplayer!") end
gmInte = gmInte || {}
gmInte.version = "0.5.0"
gmInte.config = {}
gmInte.useDataConfig = true
function gmInte.simpleLog(msg, debug)
    print(" | " .. os.date(gmInte.config.logTimestamp || "%Y-%m-%d %H:%M:%S") .. " | Gmod Integration | " .. msg)
end

local function loadConfig()
    RunConsoleCommand("sv_hibernate_think", "1")
    if !file.Exists("gm_integration", "DATA") || !file.Exists("gm_integration/config.json", "DATA") then
        file.CreateDir("gm_integration")
        file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
    else
        if gmInte.config.id && gmInte.config.id != "" then
            gmInte.useDataConfig = false
            timer.Simple(1, function() gmInte.simpleLog("Using Data Config | This is not recommended, please revert change and use ig cmd !gmi to edit your config", true) end)
            return
        end

        local oldConfig = util.JSONToTable(file.Read("gm_integration/config.json", "DATA"))
        if !oldConfig.version || (oldConfig.version < gmInte.version) then
            table.Merge(gmInte.config, oldConfig)
            gmInte.config.version = gmInte.version
            file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
        else
            gmInte.config = oldConfig
        end

        gmInte.simpleLog("Using Data Config | Data config loaded from data/gm_integration/config.json")
    end
end

local loadedFiles = {}
local function loadFile(folder, fileName)
    local path = folder .. "/" .. fileName
    if loadedFiles[path] then return end
    loadedFiles[path] = true
    if string.StartWith(fileName, "cl_") then
        if SERVER then
            AddCSLuaFile(path)
        else
            include(path)
        end
    elseif string.StartWith(fileName, "sv_") then
        if SERVER then include(path) end
    elseif string.StartWith(fileName, "sh_") then
        if SERVER then AddCSLuaFile(path) end
        include(path)
    end

    if fileName == "sv_config.lua" then loadConfig() end
    gmInte.simpleLog("File Loaded | " .. path)
end

local function loadFolder(folder)
    local files, folders = file.Find(folder .. "/*", "LUA")
    for k, fileName in SortedPairs(files) do
        loadFile(folder, fileName)
    end

    for k, subFolder in SortedPairs(folders) do
        loadFolder(folder .. "/" .. subFolder)
    end
end

print(" ")
print(" ")
print(" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
print(" -                                                                   - ")
print(" -                      Gmod Integration v" .. gmInte.version .. "                      - ")
print(" -                                                                   - ")
print(" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
print(" -                                                                   - ")
print(" -                Thanks for using Gmod Integration !                - ")
print(" -     If you have any questions, please contact us on Discord!      - ")
print(" -               https://gmod-integration.com/discord                - ")
print(" -                                                                   - ")
print(" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
print(" ")
loadFile("gmod_integration", "sv_config.lua")
loadFolder("gmod_integration/languages")
loadFolder("gmod_integration/core/utils")
loadFolder("gmod_integration/core/ui")
loadFolder("gmod_integration/core")
loadFolder("gmod_integration/modules")
loadFolder("gmod_integration")
print(" ")