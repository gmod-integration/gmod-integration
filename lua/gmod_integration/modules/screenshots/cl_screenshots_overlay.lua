hook.Add("HUDPaint", "gmInte:HUD:ShowScreenshotInfo", function()
  if !gmInte.showScreenshotInfo then return end
  local screenInfo = {
    {
      txt = "Server ID",
      val = gmInte.config.id
    },
    {
      txt = "SteamID64",
      val = LocalPlayer():SteamID64()
    },
    {
      txt = "Date",
      val = os.date("%Y-%m-%d %H:%M:%S")
    },
    {
      txt = "Position",
      val = function()
        local pos = LocalPlayer():GetPos()
        local newPos = ""
        for i = 1, 3 do
          newPos = newPos .. math.Round(pos[i])
          if i < 3 then newPos = newPos .. ", " end
        end
        return newPos
      end
    },
    {
      txt = "Map",
      val = game.GetMap()
    },
    {
      txt = "Ping",
      val = LocalPlayer():Ping()
    },
    {
      txt = "FPS",
      val = function() return math.Round(1 / FrameTime()) end
    },
    {
      txt = "Size",
      val = ScrW() .. "x" .. ScrH()
    }
  }

  local concatInfo = ""
  for k, v in pairs(screenInfo) do
    local val = v.val
    if type(val) == "function" then val = val() end
    concatInfo = concatInfo .. v.txt .. ": " .. val
    if k < #screenInfo then concatInfo = concatInfo .. " - " end
  end

  draw.SimpleText(concatInfo, "DermaDefault", ScrW() / 2, ScrH() - 15, Color(255, 255, 255, 119), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
end)

local lastTime = 0
local frameTime = 0
local fps = 0
hook.Add("Think", "gmInte:HUD:CalculateFPS", function()
  frameTime = RealTime() - lastTime
  lastTime = RealTime()
  fps = math.Round(1 / frameTime)
end)

timer.Create("gmInte:HUD:SendFPS", 5, 0, function()
  LocalPlayer().gmIntFPS = fps
  gmInte.SendNet("sendFPS", {
    ["fps"] = fps
  })
end)