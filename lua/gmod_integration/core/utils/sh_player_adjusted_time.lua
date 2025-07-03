local ply = FindMetaTable("Player")
function ply:gmIntGetTimeLastTeamChange()
  return self.gmIntTimeLastTeamChange || RealTime()
end

function ply:gmInteResetTimeLastTeamChange()
  self.gmIntTimeLastTeamChange = RealTime()
end

gmInte.restoreFileCache = gmInte.restoreFileCache || {}
function ply:getAdjustedTime()
  if gmInte.restoreFileCache == nil || gmInte.restoreFileCache.sysTime == nil || gmInte.restoreFileCache.playersList == nil then return 0 end
  if SERVER then
    if table.IsEmpty(gmInte.restoreFileCache) then
      if file.Exists("gm_integration/player_before_map_change.json", "DATA") then
        gmInte.restoreFileCache = util.JSONToTable(file.Read("gm_integration/player_before_map_change.json", "DATA"))
      else
        return 0
      end
    end
  else
    if table.IsEmpty(gmInte.restoreFileCache) then
      if file.Exists("gmod_integration/player_before_map_change.json", "DATA") then
        gmInte.restoreFileCache = util.JSONToTable(file.Read("gmod_integration/player_before_map_change.json", "DATA"))
      else
        return 0
      end

      gmInte.restoreFileCache = gmInte.restoreFileCache[gmInte.config.id]
    end
  end

  if !gmInte.restoreFileCache.sysTime || !gmInte.restoreFileCache.playersList then return 0 end
  if (gmInte.restoreFileCache.sysTime + 60 * 5) < (os.time() - self:gmIntGetConnectTime()) then return 0 end
  if !gmInte.restoreFileCache.playersList[self:SteamID()] then return 0 end
  return gmInte.restoreFileCache.playersList[self:SteamID()].connectTime || 0
end

if SERVER then
  gameevent.Listen("player_connect")
  hook.Add("player_connect", "gmInte:Player:Connect:RemoveRestore", function(data)
    if table.IsEmpty(gmInte.restoreFileCache) then
      if file.Exists("gm_integration/player_before_map_change.json", "DATA") then
        gmInte.restoreFileCache = util.JSONToTable(file.Read("gm_integration/player_before_map_change.json", "DATA"))
      else
        return
      end
    end

    if gmInte.restoreFileCache.playersList && gmInte.restoreFileCache.playersList[data.networkid] then
      gmInte.restoreFileCache.playersList[data.networkid] = nil
      file.Write("gm_integration/player_before_map_change.json", util.TableToJSON(gmInte.restoreFileCache, true))
    end
  end)
end

local function saveTimeToLocal()
  local dataToSave = {
    ["version"] = "1.0",
    ["serverID"] = gmInte.config.id,
    ["playersList"] = {},
    ["sysTime"] = os.time()
  }

  if SERVER then
    for _, ply in ipairs(player.GetAll()) do
      dataToSave.playersList[ply:SteamID()] = gmInte.getPlayerFormat(ply)
    end

    if !file.Exists("gm_integration", "DATA") then file.CreateDir("gm_integration") end
    file.Write("gm_integration/player_before_map_change.json", util.TableToJSON(dataToSave, true))
  else
    dataToSave.playersList[LocalPlayer():SteamID()] = gmInte.getPlayerFormat(LocalPlayer())
    local oldData = {}
    if file.Exists("gmod_integration/player_before_map_change.json", "DATA") then oldData = util.JSONToTable(file.Read("gmod_integration/player_before_map_change.json", "DATA")) end
    oldData[gmInte.config.id] = dataToSave
    file.Write("gmod_integration/player_before_map_change.json", util.TableToJSON(oldData, true))
  end
end

hook.Add("ShutDown", "gmInte:Server:ShutDown:SavePlayer", saveTimeToLocal)
hook.Add("GMI:SaveBeforeCrash", "gmInte:Server:BeforeCrash:SavePlayers", saveTimeToLocal)