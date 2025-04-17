hook.Add("InitPostEntity", "gmInte:Ply:Ready", function()
	gmInte.SendNet("ready", {
		["branch"] = LocalPlayer():gmInteGetBranch()
	})
end)