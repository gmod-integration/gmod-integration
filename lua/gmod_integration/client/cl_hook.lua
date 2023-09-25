//
// Hook
//

// Player Finish Init
hook.Add("InitPostEntity", "gmInte:Ply:Ready", function()
    gmInte.SendNet(0)
end)