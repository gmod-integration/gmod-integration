if game.SinglePlayer() then return print("Gmod Integration is not supported in Singleplayer!") end
local alreadyLoadGMI = gmInte
local function dllInstalled()
    return file.Exists("lua/bin/gmsv_gmod_integration_loader_linux.dll", "GAME") || file.Exists("gmsv_gmod_integration_loader_linux64.dll", "GAME") || file.Exists("lua/bin/gmsv_gmod_integration_loader_win32.dll", "GAME") || file.Exists("gmsv_gmod_integration_loader_win64.dll", "GAME")
end

local isLatest = debug.getinfo(1, "S").source == "@addons/_gmod_integration_latest/lua/autorun/_gmod_integration_latest.lua"
local isLatestExist = file.Exists("_gmod_integration_latest", "LUA")
if !alreadyLoadGMI then
    if dllInstalled() then
        if !file.Exists("gm_integration", "DATA") || !file.Exists("gm_integration/tmp.json", "DATA") then file.CreateDir("gm_integration") end
        file.Write("gm_integration/tmp.json", util.TableToJSON({
            gmod_integration_latest_updated = false,
        }, true))

        require("gmod_integration_loader")
        local tmp = util.JSONToTable(file.Read("gm_integration/tmp.json", "DATA"))
        if tmp.gmod_integration_latest_updated then
            timer.Simple(1, function()
                if game.IsDedicated() then
                    RunConsoleCommand("changelevel", game.GetMap())
                else
                    RunConsoleCommand("gamemode", game.GetMap())
                end
            end)
            return
        end

        if !isLatest then return end
    end
else
    if !isLatest && isLatestExist then return end
end

gmInte = gmInte || {}
gmInte.version = "5.0.19" // This will be automatically updated by GitHub Actions
gmInte.config = {}
gmInte.useDataConfig = true
gmInte.dllInstalled = dllInstalled
function gmInte.log(msg, onlyOndebug)
    if onlyOndebug && !gmInte.config.debug then return end
    print(" | " .. os.date(gmInte.config.logTimestamp || "%Y-%m-%d %H:%M:%S") .. " | Gmod Integration | " .. msg)
end

function gmInte.logError(msg, onlyOndebug)
    if onlyOndebug && !gmInte.config.debug then return end
    gmInte.log("ERROR | " .. msg)
end

function gmInte.logWarning(msg, onlyOndebug)
    if onlyOndebug && !gmInte.config.debug then return end
    gmInte.log("WARNING | " .. msg)
end

function gmInte.logHint(msg, onlyOndebug)
    if onlyOndebug && !gmInte.config.debug then return end
    gmInte.log("HINT | " .. msg)
end

local function loadConfig()
    RunConsoleCommand("sv_hibernate_think", "1")
    if !file.Exists("gm_integration", "DATA") || !file.Exists("gm_integration/config.json", "DATA") then
        file.CreateDir("gm_integration")
        file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
    else
        if gmInte.config.id && gmInte.config.id != "" then
            gmInte.useDataConfig = false
            timer.Simple(1, function() gmInte.log("Using Data Config | This is not recommended, please revert change and use ig cmd !gmi to edit your config", true) end)
            return
        end

        local oldConfig = util.JSONToTable(file.Read("gm_integration/config.json", "DATA"))
        if !oldConfig.version || (oldConfig.version != gmInte.version) then
            table.Merge(gmInte.config, oldConfig)
            gmInte.config.version = gmInte.version
            file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
        else
            gmInte.config = oldConfig
        end

        gmInte.log("Using Data Config: Data config loaded from data/gm_integration/config.json")
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
    gmInte.log("File Loaded: " .. path)
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

if SERVER then
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
else
    print(" ")
    print(" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
    print(" -                                                                                                                                     - ")
    print(" -                                               Gmod Integration v" .. gmInte.version .. "                                               - ")
    print(" -                                                                                                                                     - ")
    print(" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
    print(" -                                                                                                                                     - ")
    print(" -                                      Thanks for using Gmod Integration !                                     - ")
    print(" -                     If you have any questions, please contact us on Discord!                      - ")
    print(" -                                       https://gmod-integration.com/discord                                   - ")
    print(" -                                                                                                                                     - ")
    print(" - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - ")
    print(" ")
end

gmInte.execFolder = debug.getinfo(1, "S").source:match("([^/\\]+)$"):gsub("%.lua$", "") || "gmod_integration"
loadFile(gmInte.execFolder, "sv_config.lua")
loadFolder(gmInte.execFolder .. "/languages")
loadFolder(gmInte.execFolder .. "/core/utils")
loadFolder(gmInte.execFolder .. "/core/ui")
loadFolder(gmInte.execFolder .. "/core")
loadFolder(gmInte.execFolder .. "/modules")
loadFolder(gmInte.execFolder)
print(" ")