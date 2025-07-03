local ply = FindMetaTable("Player")
function ply:gmIntGetConnectTime()
    return self.gmIntTimeConnect || 0
end

function ply:gmInteGetBranch()
    return CLIENT && BRANCH || self.branch || "unknown"
end

function ply:gmIntIsAdmin()
    return gmInte.config.adminRank[self:GetUserGroup()] || false
end

function ply:gmIntGetFPS()
    return self.gmIntFPS || 0
end

function ply:gmInteSetFPS(fps)
    fps = tonumber(fps || 0)
    fps = math.Clamp(fps, 0, 1000)
    self.gmIntFPS = fps
end