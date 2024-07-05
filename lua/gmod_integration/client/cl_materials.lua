local ImageCache = {}
function gmInte.createImgurMaterials(materials, addon_var, folder, name)
    if !file.Exists(folder, "DATA") then file.CreateDir(folder) end
    local function getMatFromUrl(url, id)
        materials[id] = Material("nil")
        if file.Exists(folder .. "/" .. id .. ".png", "DATA") && !gmInte.config.redownloadMaterials then
            addon_var[id] = Material("../data/" .. folder .. "/" .. id .. ".png", "noclamp smooth")
            gmInte.log("materials", name .. " - Image Loaded - " .. id .. ".png")
            return
        end

        http.Fetch(url, function(body)
            file.Write(folder .. "/" .. id .. ".png", body)
            addon_var[id] = Material("../data/" .. folder .. "/" .. id .. ".png", "noclamp smooth")
            ImageCache[table.Count(ImageCache) + 1] = {
                ["folder"] = folder,
                ["addon_var"] = addon_var,
                ["id"] = id
            }

            gmInte.log("materials", name .. " - Image Downloaded - " .. id .. ".png")
        end)
    end

    for k, v in pairs(materials) do
        getMatFromUrl("https://i.imgur.com/" .. v .. ".png", k)
    end
end

function gmInte.redowloadMaterials()
    for k, v in pairs(ImageCache) do
        v.addon_var[v.id] = Material("../data/" .. v.folder .. "/" .. v.id .. ".png", "noclamp smooth")
        gmInte.log("materials", v.name .. " - Image Redownloaded - " .. v.id .. ".png")
    end
end

concommand.Add("gmod_integration_reload_materials", function() gmInte.redowloadMaterials() end)
local materialsList = {
    ["logo"] = "y3Mypbn"
}

gmInte.createImgurMaterials(materialsList, gmInte.materials, "gmod_integration/material", "Gmod Integration")