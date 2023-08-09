//
// Network
//

util.AddNetworkString("gmIntegration")

local netFuncs = {
    [0] = function(ply)
        gmInte.userFinishConnect(ply)
    end,
}

net.Receive("gmIntegration", function(len, ply)
    if !ply:IsPlayer() then return end
    local id = net.ReadUInt(8)
    local data = util.JSONToTable(net.ReadString() || "{}")
    // check if argument is valid
    if netFuncs[id] then
        netFuncs[id](ply, data)
    end
end)