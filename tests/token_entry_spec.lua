-- Exercise the actual write-only token control without rendering a VGUI panel.
local passed, timers, writes

local function entry(configured)
    timers, writes = {}, {}
    timer = { Simple = function(_, callback) timers[#timers + 1] = callback end }
    IsValid = function(value) return value.valid == true end
    gmInte = { getTranslation = function(_, fallback) return fallback end }
    loadGLua("lua/gmod_integration/core/config/cl_token_entry.lua")
    local input = { valid = true }
    function input:SetText(value)
        self.value = value
        if self.OnChange then self:OnChange() end
    end
    function input:GetValue() return self.value end
    function input:SetPlaceholderText(value) self.placeholder = value end
    gmInte.configureTokenEntry(input, configured, function(value) writes[#writes + 1] = value end)
    return input
end

local function flush()
    local pending = timers
    timers = {}
    for _, callback in ipairs(pending) do callback() end
end

local function test(name, callback)
    local ok, problem = pcall(callback)
    assert(ok, name .. ": " .. tostring(problem))
    passed = (passed or 0) + 1
end

test("configured credential is represented by a placeholder without a value or focus handlers", function()
    local input = entry(true)
    assert(input:GetValue() == "" and input.placeholder == "Token configured. Enter a replacement.")
    assert(input.OnGetFocus == nil and input.OnLoseFocus == nil)
    flush()
    assert(#writes == 0)
end)

test("unconfigured token starts empty without writing its placeholder", function()
    local input = entry(false)
    assert(input:GetValue() == "" and input.placeholder == "Paste your server token here.")
    input:SetText("")
    flush()
    assert(#writes == 0)
end)

test("only the latest entered replacement is submitted after the debounce", function()
    local input = entry(true)
    input:SetText("partial-fixture")
    input:SetText("new-fixture-token")
    flush()
    assert(#writes == 1 and writes[1] == "new-fixture-token")
end)

test("clearing a draft cancels the pending replacement without deleting the server token", function()
    local input = entry(true)
    input:SetText("new-fixture-token")
    input:SetText("")
    flush()
    assert(#writes == 0)
end)

test("closing the control cancels its pending replacement", function()
    local input = entry(true)
    input:SetText("new-fixture-token")
    input.valid = false
    flush()
    assert(#writes == 0)
end)

print("Token entry regressions: " .. passed .. " passed")
