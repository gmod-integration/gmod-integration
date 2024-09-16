local default = include("gmod_integration/shared/languages/sh_en.lua")
local translationTable = default
function gmInte.getTranslation(key, defaultTranslation, ...)
  local translation = translationTable[key]
  if !translation then translation = defaultTranslation end
  if ... then
    for i = 1, select("#", ...) do
      translation = string.Replace(translation, "{" .. i .. "}", select(i, ...))
    end
  end
  return translation
end

function gmInte.loadTranslations()
  local lang = gmInte.config.language
  if lang == "en" then
    translationTable = default
  else
    if file.Exists("gmod_integration/shared/languages/sh_" .. lang .. ".lua", "LUA") then
      translationTable = include("gmod_integration/shared/languages/sh_" .. lang .. ".lua")
    else
      print("Unknown Language")
      return
    end
  end

  if !gmInte.log then
    print(" | Translations | Loaded " .. lang .. " translations")
  else
    gmInte.log("Loaded " .. lang .. " translations")
  end
end

if SERVER then gmInte.loadTranslations() end