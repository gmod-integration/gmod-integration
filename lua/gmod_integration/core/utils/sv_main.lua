local function checkNewVersion()
  http.Fetch("https://api.github.com/repos/gmod-integration/gmod-integration/releases/latest", function(body, len, headers, code)
    local data = util.JSONToTable(body)
    if data and data.tag_name then
      data.tag_name = string.TrimLeft(data.tag_name, "v")
      if gmInte.compareVersion(gmInte.version, data.tag_name) == -1 then
        print(" ")
        gmInte.logHint(gmInte.getTranslation("admin.update_available", "An update is available! Latest version: {1}, you are using: {2}. If you're using the workshop version simply restart your server", data.tag_name, gmInte.version))
        print(" ")
      end
    end
  end)
end

timer.Create("gmInte:CheckVersion", 300, 0, checkNewVersion)
hook.Add("Initialize", "gmInte:CheckVersion:Initialize", function()
  timer.Simple(1, checkNewVersion)
end)