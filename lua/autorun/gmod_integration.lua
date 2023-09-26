if game.SinglePlayer() then return end

//
// Variables
//

gmInte = gmInte || {}
gmInte.version = "0.1.2"
gmInte.config = gmInte.config || {}

//
// Functions
//

local function loadAllFiles(folder)
    local files, folders = file.Find(folder .. "/*", "LUA")
    for k, v in SortedPairs(files) do
        local path = folder .. "/" .. v
        print(" | Loading File | " .. path)
        if string.StartWith(v, "cl_") then
            if SERVER then
                AddCSLuaFile(path)
            else
                include(path)
            end
        elseif string.StartWith(v, "sv_") then
            if SERVER then
                include(path)
            end
        elseif string.StartWith(v, "sh_") then
            if SERVER then
                AddCSLuaFile(path)
            end
            include(path)
        end
    end
    for k, v in SortedPairs(folders, true) do
        loadAllFiles(folder .. "/" .. v, name)
    end
end

//
// Load Files
//

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

//
// Init Data Folder and Load Config
//

if (SERVER) then
	RunConsoleCommand("sv_hibernate_think", "1")

    if (!file.Exists("gm_integration", "DATA") || !file.Exists("gm_integration/config.json", "DATA")) then
        file.CreateDir("gm_integration")
        file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
    else
        if (gmInte.config.id && gmInte.config.id != "") then return end

        local oldConfig = util.JSONToTable(file.Read("gm_integration/config.json", "DATA"))
        if (!oldConfig.version || (oldConfig.version < gmInte.version)) then
            if (oldConfig.version < "0.1.2") then
                gmInte.config.id = oldConfig.id
                gmInte.config.token = oldConfig.token
            else
                table.Merge(gmInte.config, oldConfig)
            end
            gmInte.config.version = gmInte.version
            file.Write("gm_integration/config.json", util.TableToJSON(gmInte.config, true))
        else
            gmInte.config = oldConfig
        end
    end
end