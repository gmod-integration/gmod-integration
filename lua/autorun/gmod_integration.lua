if game.SinglePlayer() then return print("Gmod Integration is not supported in Singleplayer!") end
gmInte = gmInte || {}
gmInte.version = "0.4.3"
gmInte.config = {}
gmInte.materials = {}
local function loadServerConfig()
    RunConsoleCommand("sv_hibernate_think", "1")
    if !file.Exists("gm_integration", "DATA") || !file.Exists("gm_integration/config.json", "DATA") then
        file.CreateDir("gm_integration")
        file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
    else
        if gmInte.config.id && gmInte.config.id != "" then return end
        local oldConfig = util.JSONToTable(file.Read("gm_integration/config.json", "DATA"))
        if !oldConfig.version || (oldConfig.version < gmInte.version) then
            print(" | Merging Config | gmod_integration/sv_config.lua")
            table.Merge(gmInte.config, oldConfig)
            gmInte.config.version = gmInte.version
            file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
        else
            gmInte.config = oldConfig
        end
    end
end

local function loadAllFiles(folder)
    local files, folders = file.Find(folder .. "/*", "LUA")
    for k, fileName in SortedPairs(files) do
        local path = folder .. "/" .. fileName
        print(" | Loading File | " .. path)
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

        if fileName == "sv_config.lua" then
            loadServerConfig()
            continue
        end
    end

    for k, v in SortedPairs(folders, true) do
        loadAllFiles(folder .. "/" .. v, name)
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
loadAllFiles("gmod_integration")
print(" ")