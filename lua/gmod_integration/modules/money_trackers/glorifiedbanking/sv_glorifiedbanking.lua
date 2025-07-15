-- https://github.com/GlorifiedPig/GlorifiedBanking

function gmInte.postGlorifiedBankingTakeMoney(ply, amount, reason)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/ch-atm/take-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["amount"] = math.Round(amount),
    ["reason"] = reason
  })
end

function gmInte.postGlorifiedBankingReceiveMoney(ply, amount, reason)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/ch-atm/receive-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["amount"] = math.Round(amount),
    ["reason"] = reason
  })
end

function gmInte.postGlorifiedBankingSendMoney(ply, amount, plyReceiver)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  if !plyReceiver:IsValid() || !plyReceiver:IsPlayer(plyReceiver) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/ch-atm/send-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["receiver"] = gmInte.getPlayerFormat(plyReceiver),
    ["amount"] = math.Round(amount)
  })
end

function gmInte.postGlorifiedBankingWithdrawMoney(ply, amount)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/ch-atm/withdraw-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["amount"] = math.Round(amount)
  })
end

function gmInte.postGlorifiedBankingDepositMoney(ply, amount)
  if !ply:IsValid() || !ply:IsPlayer(ply) then return end
  gmInte.http.postLog("/servers/:serverID/players/" .. ply:SteamID64() .. "/ch-atm/deposit-money", {
    ["player"] = gmInte.getPlayerFormat(ply),
    ["amount"] = math.Round(amount)
  })
end

hook.Add("GlorifiedBanking.FeeTaken", "gmInte:Player:GlorifiedBanking:TakeMoney", function(amount, ply, reason) gmInte.postGlorifiedBankingTakeMoney(ply, amount, reason) end)
hook.Add("GlorifiedBanking.PlayerInterestReceived", "gmInte:Player:GlorifiedBanking:PlayerInterestReceived", function(amount, ply, reason) gmInte.postGlorifiedBankingReceiveMoney(ply, amount, reason) end)
hook.Add("GlorifiedBanking.PlayerTransfer", "gmInte:Player:GlorifiedBanking:SendMoney", function(ply, amount, plyReceiver) gmInte.postGlorifiedBankingSendMoney(ply, amount, plyReceiver) end)
hook.Add("GlorifiedBanking.PlayerWithdrawal", "gmInte:Player:GlorifiedBanking:WithdrawMoney", function(ply, amount) gmInte.postGlorifiedBankingWithdrawMoney(ply, amount) end)
hook.Add("GlorifiedBanking.PlayerDeposit", "gmInte:Player:GlorifiedBanking:DepositMoney", function(ply, amount) gmInte.postGlorifiedBankingDepositMoney(ply, amount) end)