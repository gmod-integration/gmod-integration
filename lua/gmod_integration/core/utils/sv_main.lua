timer.Create("gmInte:CheckVersion", 60, 0, function()
  http.Fetch("https://api.github.com/repos/gmod-integration/gmod-integration/releases/latest", function(body, len, headers, code)
    local data = util.JSONToTable(body)
    if data and data.tag_name then
      data.tag_name = string.TrimLeft(data.tag_name, "v")
      if gmInte.compareVersion(gmInte.version, data.tag_name) == -1 then
        print(" ")
        gmInte.logHint(gmInte.getTranslation("admin.update_available", "An update is available! Latest version: " .. data.tag_name .. ", you are using: " .. gmInte.version))
        print(" ")
      end
    end
  end)
end)