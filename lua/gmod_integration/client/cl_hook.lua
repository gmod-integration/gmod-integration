hook.Add("InitPostEntity", "gmInte:Ply:Ready", function()
	gmInte.SendNet("ready", {
		["branch"] = LocalPlayer():gmInteGetBranch()
	})
end)

hook.Add("OnPlayerChat", "gmInte:OnPlayerChat:AdminCmd", function(ply, strText, bTeamOnly, bPlayerIsDead)
	if ply != LocalPlayer() then return end
	strText = string.lower(strText)
	if strText == "/gmi" || strText == "!gmi" then
		gmInte.openAdminConfig()
		return true
	end
end)