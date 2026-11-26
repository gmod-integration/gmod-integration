-- Exercise the actual report dialog and acknowledgement callbacks with mocked VGUI and capture APIs.
local passes, failures = 0, {}
local hooks, timers, frames, entries, dropdowns, buttons, requests, notices, cancelled, files, captureResult
local compressionBytes, compressionCalls, encodingCalls

local function jsonEncode(value)
    if type(value) == "string" then
        return '"' .. value:gsub('[%z\1-\31\\"]', function(character)
            return string.format('\\u%04x', string.byte(character))
        end) .. '"'
    end
    if type(value) == "number" or type(value) == "boolean" then return tostring(value) end
    local entries = {}
    for key, child in pairs(value) do entries[#entries + 1] = jsonEncode(key) .. ':' .. jsonEncode(child) end
    return '{' .. table.concat(entries, ',') .. '}'
end

local function reset()
    SERVER, CLIENT = false, true
    hooks, timers, frames, entries, dropdowns, buttons, requests, notices, cancelled, files = {}, {}, {}, {}, {}, {}, {}, {}, {}, {}
    captureResult = "private screenshot bytes"
    compressionBytes, compressionCalls, encodingCalls = nil, 0, 0
    NOTIFY_GENERIC, NOTIFY_ERROR, NOTIFY_HINT = 0, 1, 3
    isstring = function(value) return type(value) == "string" end
    istable = function(value) return type(value) == "table" end
    IsValid = function(value) return type(value) == "table" and value.valid == true end
    Color = function(...) return { ... } end
    LocalPlayer = function() return { SteamID64 = function() return "76561198012345678" end } end
    ScrW, ScrH = function() return 1920 end, function() return 1080 end
    math.Round = function(value) return math.floor(value + 0.5) end
    hook = { Add = function(event, name, callback) hooks[event .. ":" .. name] = callback end }
    timer = {
        Create = function(name, _, _, callback) timers[name] = callback end,
        Remove = function(name) timers[name] = nil end,
        Simple = function(_, callback) callback() end,
    }
    file = {
        Exists = function(path) return files[path] ~= nil end,
        CreateDir = function(path) files[path] = true end,
        Write = function(path, data) files[path] = data end,
    }
    render = { Capture = function() return captureResult end }
    util = {
        CRC = function() return "synthetic-id" end,
        Base64Encode = function(value, inline)
            assert(inline == true)
            encodingCalls = encodingCalls + 1
            return string.rep("A", math.ceil(#value / 3) * 4)
        end,
        TableToJSON = jsonEncode,
        Compress = function(value)
            assert(#requests == 0, "Optional captures must be checked before any report is sent")
            compressionCalls = compressionCalls + 1
            return compressionBytes and string.rep("C", compressionBytes) or "packed:" .. #value
        end,
    }
    notification = { AddLegacy = function(message, kind) notices[#notices + 1] = { message = message, kind = kind } end }
    concommand = { Add = function() end }
    local methods = {
        SetText = function(self, text) self.text = text end,
        GetText = function(self) return self.text or "" end,
        SetSize = function(self, width, height) self.width, self.height = width, height end,
        GetWide = function(self) return self.width or 500 end,
        SetColWide = function(self, width) self.columnWidth = width end,
        GetColWide = function(self) return self.columnWidth end,
        SetRowHeight = function(self, height) self.rowHeight = height end,
        GetRowHeight = function(self) return self.rowHeight end,
        AddChoice = function() end,
        GetSelected = function(self) if self.level then return "Selected importance", self.level end end,
        SetEnabled = function(self, enabled) self.enabled = enabled end,
        Close = function(self) self.valid = false; if self.OnClose then self.OnClose() end end,
    }
    for _, name in ipairs({ "Dock", "DockMargin", "Center", "SetTitle", "MakePopup", "SetFont", "SetWrap", "SetBackgroundColor", "SetMultiline", "SetTall", "SetPlaceholderText", "SetSortItems", "SetValue", "SetImage", "SetCols", "AddItem" }) do
        methods[name] = function() end
    end
    vgui = { Create = function(class)
        local widget = setmetatable({ valid = true, class = class, enabled = true }, { __index = methods })
        if class == "DFrame" then frames[#frames + 1] = widget end
        if class == "DTextEntry" then entries[#entries + 1] = widget end
        if class == "DComboBox" then dropdowns[#dropdowns + 1] = widget end
        if class == "DButton" then buttons[#buttons + 1] = widget end
        return widget
    end }
    gmInte = {
        config = { id = "server-one" },
        getTranslation = function(_, fallback) return fallback end,
        getFrameName = function(title) return title end,
        getPlayerFormat = function() return { steamID64 = "76561198012345678" } end,
        applyPaint = function() end,
        chatAddText = function(_, message) notices[#notices + 1] = { message = message } end,
        cancelClientAPI = function(id) cancelled[#cancelled + 1] = id end,
        api = { post = function(endpoint, body, success, failed)
            requests[#requests + 1] = { endpoint = endpoint, body = body, success = success, failed = failed }
            return "report-" .. #requests
        end },
    }
    loadGLua("lua/gmod_integration/modules/report_bugs/cl_report_bug.lua")
end

local function open(capture)
    gmInte.openReportBug()
    if capture ~= false then hooks["PostRender:gmInte:BugReport:Screenshot"]() end
    timers["gmInte:BugReport:Screenshot:Open"]()
    for _, entry in ipairs(entries) do entry.text = "private report field" end
    dropdowns[1].level = "high"
    return frames[1], buttons[1]
end

local function test(name, callback)
    reset()
    local ok, message = pcall(callback)
    if ok then passes = passes + 1 else failures[#failures + 1] = name .. ": " .. tostring(message) end
end

test("accepted reports with failed captures are terminal partial success, not retryable failed reports", function()
    local frame, submit = open()
    submit.DoClick()
    submit.DoClick()
    assert(#requests == 1 and submit.enabled == false)
    requests[1].success(200, { success = true, saved = true, attachment = "failed", error = "private storage secret" })
    assert(#notices == 1 and notices[1].kind == NOTIFY_HINT)
    assert(notices[1].message:find("Bug report saved", 1, true) and notices[1].message:find("Do not resend", 1, true))
    assert(not notices[1].message:find("private", 1, true) and not frame.valid and #cancelled == 0)
    frame.valid = true
    requests[1].failed(503, { error = "late failure" })
    submit.DoClick()
    assert(#requests == 1 and #notices == 1 and submit.enabled == false)
end)

test("confirmed report and capture storage has its own success message", function()
    local frame, submit = open()
    submit.DoClick()
    requests[1].success(200, { saved = true, attachment = "saved" })
    assert(notices[1].message == "Bug report and screenshot saved." and notices[1].kind == NOTIFY_GENERIC)
    assert(not frame.valid and #cancelled == 0)
end)

test("an acknowledged report without an attachment does not claim a screenshot was saved", function()
    local _, submit = open(false)
    submit.DoClick()
    assert(next(requests[1].body.screenshot) == nil)
    requests[1].success(200, { saved = true, attachment = "none" })
    assert(notices[1].message == "Bug report saved.")
end)

test("an attempted capture omitted from the accepted report is still a visible partial success", function()
    local _, submit = open()
    submit.DoClick()
    requests[1].success(200, { saved = true, attachment = "none" })
    assert(notices[1].message:find("screenshot could not be attached", 1, true))
    assert(notices[1].message:find("Do not resend", 1, true))
end)

test("legacy or malformed attachment acknowledgements never claim the attempted screenshot arrived", function()
    local frame, submit = open()
    submit.DoClick()
    requests[1].success(200, { success = true, id = 12, attachment = "private exception", token = "private secret" })
    assert(notices[1].message:find("screenshot status could not be confirmed", 1, true))
    assert(notices[1].message:find("Check the web panel", 1, true) and not notices[1].message:find("private", 1, true))
    assert(not frame.valid and #requests == 1)
end)

test("legacy acceptance without a screenshot stays compatible and does not invent storage confirmation", function()
    local _, submit = open(false)
    submit.DoClick()
    requests[1].success(200, { success = true })
    assert(notices[1].message == "Bug report accepted.")
end)

test("an engine capture failure is explicitly carried as an optional attachment failure", function()
    captureResult = nil
    local _, submit = open()
    submit.DoClick()
    assert(requests[1].body.screenshot.invalid == true)
    requests[1].success(200, { saved = true, attachment = "failed" })
    assert(notices[1].message:find("screenshot could not be attached", 1, true))
end)

test("a capture over the 6 MiB compressed relay budget is dropped before sending one preserved report", function()
    captureResult = string.rep("private capture", 400000)
    compressionBytes = 6 * 1024 * 1024 + 1
    local frame, submit = open()
    submit.DoClick()
    assert(compressionCalls == 1 and #requests == 1)
    assert(requests[1].body.screenshot.invalid == true and requests[1].body.screenshot.screenshot == nil)
    assert(requests[1].body.description == "private report field" and requests[1].body.steps == "private report field")
    requests[1].success(200, { saved = true, attachment = "failed" })
    assert(not frame.valid and notices[1].message:find("Do not resend", 1, true))
    submit.DoClick()
    assert(#requests == 1)
end)

test("a report over the 10 MiB JSON budget loses only its optional capture", function()
    captureResult = string.rep("C", 6 * 1024 * 1024)
    gmInte.getPlayerFormat = function() return { customValues = { localDetail = string.rep("M", 3 * 1024 * 1024) } } end
    local _, submit = open()
    submit.DoClick()
    assert(compressionCalls == 0 and #requests == 1)
    assert(requests[1].body.screenshot.invalid == true and requests[1].body.description == "private report field")
    assert(#util.TableToJSON(requests[1].body) < 10 * 1024 * 1024)
end)

test("oversized engine captures do not allocate another base64 copy or block the report", function()
    captureResult = string.rep("C", 8 * 1024 * 1024)
    local _, submit = open()
    submit.DoClick()
    assert(encodingCalls == 0 and compressionCalls == 0 and #requests == 1)
    assert(requests[1].body.screenshot.invalid == true and requests[1].body.actual == "private report field")
end)

test("the exact compressed limit still preserves a fitting capture", function()
    compressionBytes = 6 * 1024 * 1024
    local _, submit = open()
    submit.DoClick()
    assert(#requests == 1 and compressionCalls == 1)
    assert(isstring(requests[1].body.screenshot.screenshot) and requests[1].body.screenshot.invalid == nil)
end)

test("capture preparation failures preserve the report without any automatic resend", function()
    for _, stage in ipairs({ "encoding", "json", "compression" }) do
        reset()
        if stage == "encoding" then util.Base64Encode = function() error("private capture failure") end end
        if stage == "json" then util.TableToJSON = function() error("private serialization failure") end end
        if stage == "compression" then util.Compress = function() error("private compression failure") end end
        local _, submit = open()
        submit.DoClick()
        assert(#requests == 1 and requests[1].body.screenshot.invalid == true)
        assert(requests[1].body.expected == "private report field")
        requests[1].success(200, { saved = true, attachment = "failed" })
        assert(notices[1].message:find("Do not resend", 1, true))
        assert(not notices[1].message:find("private", 1, true))
        submit.DoClick()
        assert(#requests == 1)
    end
end)

test("a rejected request preserves the editable report and requires a deliberate retry", function()
    local _, submit = open()
    submit.DoClick()
    requests[1].failed(429, { error = "private rate data" })
    assert(#requests == 1 and submit.enabled == true)
    assert(entries[1].text == "private report field")
    submit.DoClick()
    assert(#requests == 2 and requests[2].body.description == requests[1].body.description)
end)

if #failures > 0 then error(table.concat(failures, "\n")) end
print("Bug report acknowledgement regressions: " .. passes .. " passed")
