local ply = FindMetaTable("Player")
function ply:gmIntIsVerified()
  return self.gmIntVerified || false
end