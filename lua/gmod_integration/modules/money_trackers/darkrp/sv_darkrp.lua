function gmInte.postDarkRPDroppedMoney(ply, amount, entity)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/dark-rp/drop-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["amount"] = math.Round(amount),
    ["entity"] = gmInte.getEntityFormat(entity),
  })
end

function gmInte.postDarkRPPickedUpMoney(ply, price, entity)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/dark-rp/picked-up-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["amount"] = math.Round(price),
    ["entity"] = gmInte.getEntityFormat(entity),
  })
end

function gmInte.postDarkRPPickedUpCheque(plyWriter, plyTarget, price, sucess, entity)
  if !plyWriter:IsValid() || !plyWriter:IsPlayer() then return end
  if !plyTarget:IsValid() || !plyTarget:IsPlayer() then return end
  if ply != plyTo then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/dark-rp/picked-up-cheque", {
    ["playerChequeWriter"] = gmInte.getPlayerFormat(plyWriter),
    ["playerChequeTarget"] = gmInte.getPlayerFormat(plyTarget),
    ["amount"] = math.Round(price),
    ["entity"] = gmInte.getEntityFormat(entity),
  })
end

hook.Add("playerDroppedMoney", "gmInte:Player:DarkRPDroppedMoney", function(ply, amount, entity) gmInte.postDarkRPDroppedMoney(ply, amount, entity) end)
hook.Add("playerPickedUpMoney", "gmInte:Player:DarkRPPickedUpMoney", function(ply, price, entity) gmInte.postDarkRPPickedUpMoney(ply, price, entity) end)
hook.Add("playerDroppedCheque", "gmInte:Player:DarkRPPickedUpCheque", function(plyWriter, plyTarget, price, sucess, entity) gmInte.postDarkRPPickedUpCheque(plyWriter, plyTarget, price, sucess, entity) end)