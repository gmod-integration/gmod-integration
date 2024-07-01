local colorTbl = {
    ["background"] = Color(41, 44, 54),
    ["primary"] = Color(58, 62, 73),
    ["primary-active"] = Color(58, 62, 73, 163),
    ["secondary"] = Color(44, 47, 59),
    ["secondary-active"] = Color(31, 33, 40),
    ["green"] = Color(78, 151, 53),
    ["green-active"] = Color(58, 122, 38),
    ["orange"] = Color(204, 145, 62),
    ["orange-active"] = Color(168, 122, 43),
    ["red"] = Color(201, 59, 59),
    ["red-active"] = Color(168, 43, 43),
    ["blue"] = Color(67, 197, 214),
    ["blue-active"] = Color(41, 152, 167),
    ["purple"] = Color(73, 90, 252),
    ["purple-active"] = Color(47, 63, 159),
    ["font"] = Color(255, 255, 255),
    ["font-secondary"] = Color(179, 179, 179)
}

// con cmd how create a error
concommand.Add("gmi_error", function()
    error("This is a test error")
end)

function gmInte.getColor(name)
    return colorTbl[name]
end

function gmInte.applyPaint(element, id)
    if (element.DoClick) then
        element:SetTextColor(gmInte.getColor("font"))

        element.Paint = function(self, w, h)
            local color = gmInte.getColor("primary")

            if (self:IsHovered()) then
                color = gmInte.getColor("primary-active")
            end

            draw.RoundedBox(0, 0, 0, w, h, color)
        end
    elseif (element.SetTitle) then
        element.Paint = function(self, w, h)
            draw.RoundedBox(0, 0, 0, w, h, gmInte.getColor("background"))
            // first 20px = title bar = primary
            draw.RoundedBox(0, 0, 0, w, 22, gmInte.getColor("primary"))
        end
    end
end

function gmInte.getFrameName(name)
    return "Gmod Integration v" .. (gmInte.version || "0.0.0") .. " - " .. name
end