// Meta
local ply = FindMetaTable("Player")

function ply:gmInteGetTotalMoney()
    // if darkrp
    if DarkRP then
        return self:getDarkRPVar("money")
    end

    // else
    return 0
end