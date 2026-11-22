local function checkNewVersion()
  if !gmInte.aprovedCredentials then return end
  gmInte.api.get("/servers/:serverID", function(_, data)
    if !istable(data) || !isstring(data.latestVersion) then return end
    local latest = string.gsub(data.latestVersion, "^v", "")
    if !string.match(latest, "^%d+%.%d+%.%d+$") then return end
    if gmInte.compareVersion(gmInte.version, latest) == -1 then
      gmInte.logHint(gmInte.getTranslation("admin.update_available", "An update is available! Latest version: {1}, you are using: {2}. If you're using the workshop version simply restart your server", latest, gmInte.version))
    end
  end)
end

timer.Create("gmInte:CheckVersion", 300, 0, checkNewVersion)
hook.Add("GmodIntegration:Websocket:Ready", "gmInte:CheckVersion:Connected", checkNewVersion)
