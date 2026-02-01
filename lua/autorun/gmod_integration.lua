if game.SinglePlayer() then return print("Gmod Integration is not supported in Singleplayer!") end

gmInte = gmInte || {}
gmInte.version = "5.2.1" // This will be automatically updated by GitHub Actions
gmInte.config = {}
gmInte.useDataConfig = true
gmInte.detectOS = detectOS

function gmInte.compareVersion(v1, v2) // Returns -1 if v1 < v2, 0 if v1 == v2, 1 if v1 > v2
    local function parseVersion(v)
        local major, minor, patch = v:match("^(%d+)%.(%d+)%.(%d+)$")
        return tonumber(major) || 0, tonumber(minor) || 0, tonumber(patch) || 0
    end

    local major1, minor1, patch1 = parseVersion(v1)
    local major2, minor2, patch2 = parseVersion(v2)

    if major1 < major2 then return -1 end
    if major1 > major2 then return 1 end

    if minor1 < minor2 then return -1 end
    if minor1 > minor2 then return 1 end

    if patch1 < patch2 then return -1 end
    if patch1 > patch2 then return 1 end

    return 0
end
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
        if !oldConfig.version || gmInte.compareVersion(oldConfig.version, gmInte.version) == -1 then
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

    if fileName == "sv_default_config.lua" then loadConfig() end
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
loadFile(gmInte.execFolder .. "/core/config", "sv_default_config.lua")
loadFolder(gmInte.execFolder .. "/languages")
loadFolder(gmInte.execFolder .. "/core/utils")
loadFolder(gmInte.execFolder .. "/core/ui")
loadFolder(gmInte.execFolder .. "/core")
loadFolder(gmInte.execFolder .. "/modules")
loadFolder(gmInte.execFolder)
print(" ")