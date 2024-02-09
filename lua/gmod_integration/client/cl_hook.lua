//
// Hook
//

// Player Finish Init
hook.Add("InitPostEntity", "gmInte:Ply:Ready", function()
    gmInte.SendNet(0)
end)

hook.Add("OnPlayerChat", "gmInte:OnPlayerChat:AdminCmd", function(ply, strText, bTeamOnly, bPlayerIsDead)
    if (ply != LocalPlayer()) then return end

	strText = string.lower(strText)

	if (strText == "/gmi") then
        gmInte.openAdminConfig()
		return true
	end
end)