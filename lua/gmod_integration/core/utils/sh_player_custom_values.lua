local ply = FindMetaTable("Player")
function ply:gmIntSetCustomValue(key, value)
  self.gmIntCustomValues = self.gmIntCustomValues || {}
  self.gmIntCustomValues[key] = value
end

function ply:gmIntGetCustomValue(key)
  return self.gmIntCustomValues && self.gmIntCustomValues[key]
end

function ply:gmIntRemoveCustomValue(key)
  if self.gmIntCustomValues then self.gmIntCustomValues[key] = nil end
end

local function getCustomCompatability(ply)
  local values = {}
  // DarkRP
  if DarkRP then
    values.money = ply:getDarkRPVar("money")
    values.job = ply:getDarkRPVar("job")
  end

  // GUI Level System
  if GUILevelSystem then
    values.level = ply:GetLevel()
    values.xp = ply:GetXP()
  end

  // Pointshop 2
  if Pointshop2 && ply.PS2_Wallet then
    values.ps2Points = ply.PS2_Wallet.points
    values.ps2PremiumPoints = ply.PS2_Wallet.premiumPoints
  end

  if CH_ATM && SERVER then values.bank = CH_ATM.GetMoneyBankAccount(ply) end
  return values
end

local function getCustomValues(ply)
  local values = {}
  // Get compatability values
  for key, value in pairs(getCustomCompatability(ply)) do
    values[key] = value
  end

  // Get custom values or overwrite compatability values
  if ply.gmIntCustomValues then
    for key, value in pairs(ply.gmIntCustomValues) do
      values[key] = value
    end
  end
  return values
end

function ply:gmIntGetCustomValues()
  return getCustomValues(self)
end