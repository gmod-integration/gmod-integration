function gmInte.postCHATMTakeMoney(ply, amount, reason)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/ch-atm/take-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["amount"] = math.Round(amount),
    ["reason"] = reason
  })
end

function gmInte.postCHATMReceiveMoney(ply, amount, reason)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/ch-atm/receive-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["amount"] = math.Round(amount),
    ["reason"] = reason
  })
end

function gmInte.postCHATMSendMoney(ply, amount, plyReceiver)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  if !plyReceiver:IsValid() || !plyReceiver:IsPlayer(plyReceiver) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/ch-atm/send-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["receiver"] = gmInte.getPlayerFormat(plyReceiver),
    ["amount"] = math.Round(amount)
  })
end

function gmInte.postCHATMWithdrawMoney(ply, amount)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/ch-atm/withdraw-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["amount"] = math.Round(amount)
  })
end

function gmInte.postCHATMDepositMoney(ply, amount)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/ch-atm/deposit-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["amount"] = math.Round(amount)
  })
end

hook.Add("CH_ATM_bLogs_TakeMoney", "gmInte:Player:CH:ATM:TakeMoney", function(amount, ply, reason) gmInte.postCHATMTakeMoney(ply, amount, reason) end)
hook.Add("CH_ATM_bLogs_ReceiveMoney", "gmInte:Player:CH:ATM:ReceiveMoney", function(amount, ply, reason) gmInte.postCHATMReceiveMoney(ply, amount, reason) end)
hook.Add("CH_ATM_bLogs_SendMoney", "gmInte:Player:CH:ATM:SendMoney", function(ply, amount, plyReceiver) gmInte.postCHATMSendMoney(ply, amount, plyReceiver) end)
hook.Add("CH_ATM_bLogs_WithdrawMoney", "gmInte:Player:CH:ATM:WithdrawMoney", function(ply, amount) gmInte.postCHATMWithdrawMoney(ply, amount) end)
hook.Add("CH_ATM_bLogs_DepositMoney", "gmInte:Player:CH:ATM:DepositMoney", function(ply, amount) gmInte.postCHATMDepositMoney(ply, amount) end)