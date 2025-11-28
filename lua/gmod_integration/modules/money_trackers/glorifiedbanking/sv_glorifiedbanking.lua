-- https://github.com/GlorifiedPig/GlorifiedBanking

function gmInte.postGlorifiedBankingTakeMoney(ply, amount, reason)
  if amount <= 0 then return end
  if !ply:IsValid() || !ply:IsPlayer(ply) then print("bla") return end
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

hook.Add("GlorifiedBanking.FeeTaken", "gmInte:Player:GlorifiedBanking:TakeMoney", function(ply, amount) gmInte.postGlorifiedBankingTakeMoney(ply, amount, "Fee Taken") end)
hook.Add("GlorifiedBanking.PlayerInterestReceived", "gmInte:Player:GlorifiedBanking:PlayerInterestReceived", function(ply, amount) gmInte.postGlorifiedBankingReceiveMoney(ply, amount, "Interest Received") end)
hook.Add("GlorifiedBanking.PlayerTransfer", "gmInte:Player:GlorifiedBanking:SendMoney", function(ply, plyReceiver, amount) gmInte.postGlorifiedBankingSendMoney(ply, amount, plyReceiver) end)
hook.Add("GlorifiedBanking.PlayerWithdrawal", "gmInte:Player:GlorifiedBanking:WithdrawMoney", function(ply, amount) gmInte.postGlorifiedBankingWithdrawMoney(ply, amount) end)
hook.Add("GlorifiedBanking.PlayerDeposit", "gmInte:Player:GlorifiedBanking:DepositMoney", function(ply, amount) gmInte.postGlorifiedBankingDepositMoney(ply, amount) end)

hook.Add("GlorifiedBanking.PlayerBalanceUpdated", "gmInte:Player:GlorifiedBanking:BalanceUpdated", function(ply, iOldBank, iNewBank)
    if iOldBank > iNewBank then
        gmInte.postGlorifiedBankingTakeMoney(ply, iOldBank - iNewBank, "Balance Updated")
    elseif iOldBank < iNewBank then
        gmInte.postGlorifiedBankingReceiveMoney(ply, iNewBank - iOldBank, "Balance Updated")
    end
end)