function gmInte.playerWarn(ply, admin, reason)
  gmInte.api.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/warns", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["admin"] = gmInte.getPlayerFormat(admin),
    ["reason"] = reason,
    ["date"] = os.time()
  })
end

function gmInte.playerWarnID(plySteamID64, adminSteamID64, reason)
  gmInte.api.post("/servers/:serverID/players/" .. plySteamID64 .. "/warns", {
    ["adminSteamID64"] = adminSteamID64,
    ["reason"] = reason,
    ["date"] = os.time()
  })
end

local exportingWarns = false
function gmInte.serverExportWarns(data)
  if exportingWarns || !istable(data) || #data == 0 then return false end
  local snapshot = table.Copy(data)
  local position = 1
  exportingWarns = true
  local function nextBatch()
    if position > #snapshot then
      exportingWarns = false
      gmInte.log("Warning export completed (" .. #snapshot .. " warnings)")
      return
    end
    local batch = {}
    for index = position, math.min(position + 499, #snapshot) do
      table.insert(batch, snapshot[index])
    end
    local batchIndex = math.floor((position - 1) / 500) + 1
    gmInte.api.post("/servers/:serverID/warns", { warns = batch }, function()
      position = position + #batch
      nextBatch()
    end, function(status)
      exportingWarns = false
      gmInte.logError("Warning export stopped at batch " .. batchIndex .. " (status " .. tostring(status) .. "). Run export-warns again to retry.")
    end)
  end
  nextBatch()
  return true
end

if AWarn then
  hook.Add("AWarnPlayerWarned", "AWarn3WarningDiscordRelay", function(pl, aID, reason)
    local admin = AWarn:GetPlayerFromID64(aID)
    if !admin then return end
    gmInte.playerWarn(pl, admin, reason)
  end)

  hook.Add("AWarnPlayerIDWarned", "AWarn3IDWarningDiscordRelay", function(pID, aID, reason)
    local admin = AWarn:GetPlayerFromID64(aID)
    if !admin then return end
    gmInte.playerWarnID(pID, aID, reason)
  end)

  hook.Add("GmodIntegration:ExportWarns", "AWarn3ExportWarns", function()
    local query = "SELECT * FROM awarn3_warningtable"
    AWarn3_MySQLite.query(query, function(result)
      if !result then return end
      local warns = {}
      for k, v in ipairs(result) do
        table.insert(warns, {
          playerSteamID64 = v.PlayerID,
          adminSteamID64 = v.AdminID,
          reason = v.WarningReason,
          date = v.WarningDate
        })
      end

      gmInte.serverExportWarns(warns)
    end, function(err) gmInte.logError("AWarn3", "Failed to export warns: " .. err) end)
  end)
end
