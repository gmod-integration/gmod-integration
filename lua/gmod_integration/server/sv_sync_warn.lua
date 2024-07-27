function gmInte.playerWarn(ply, admin, reason)
  gmInte.http.post("/servers/:serverID/players/" .. ply:SteamID64() .. "/warns", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["admin"] = gmInte.getPlayerFormat(admin),
    ["reason"] = reason
  })
end

function gmInte.playerWarnID(plySteamID64, adminSteamID64, reason)
  gmInte.http.post("/servers/:serverID/players/" .. plySteamID64 .. "/warns", {
    ["adminSteamID64"] = adminSteamID64,
    ["reason"] = reason
  })
end

function gmInte.serverExportWarns(data)
  gmInte.http.post("/servers/:serverID/warns", {
    ["warns"] = data
  })
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
      for k, v in pairs(result) do
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