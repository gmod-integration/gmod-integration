function gmInte.wsRunLua(data)
  gmInte.log("Lua Runner from Discord '" .. data.data .. "' by " .. data.steamID)
  RunString(data.data, "GMI Discord Lua Runner", true)
end

function gmInte.wsServerRunLua(data)
  RunString(data.data, "GMI Discord Lua Runner", true)
end