-- Exercise the real client screenshot state machine with mocked rendering and net relay.
local passed, failures = 0, {}
local hooks, commands, clock, consoleOpen, gameMenuOpen, captures, requests, notices, logs, captureResult, localPlayer

local function reset()
    SERVER, CLIENT = false, true
    hooks, commands, clock, consoleOpen, gameMenuOpen, captures, requests, notices, logs = {}, {}, 0, false, false, {}, {}, {}, {}
    captureResult = "synthetic-image-bytes"
    localPlayer = {}
    isstring = function(value) return type(value) == "string" end
    istable = function(value) return type(value) == "table" end
    CurTime = function() return clock end
    LocalPlayer = function() return localPlayer end
    ScrW = function() return 1920 end
    ScrH = function() return 1080 end
    Color = function(...) return { ... } end
    math.Round = function(value) return math.floor(value + 0.5) end
    string.Explode = function(separator, text)
        local values = {}
        for value in (text .. separator):gmatch("(.-)" .. separator) do values[#values + 1] = value end
        return values
    end
    hook = { Add = function(event, id, callback) hooks[event .. ":" .. id] = callback end }
    gui = {
        IsConsoleVisible = function() return consoleOpen end,
        IsGameUIVisible = function() return gameMenuOpen end,
        HideGameUI = function() error("A screenshot must not close the user's menus") end,
    }
    concommand = { Add = function(name, callback) commands[name] = callback end }
    render = { Capture = function(data) captures[#captures + 1] = data; return captureResult end }
    util = { Base64Encode = function(_, inline) assert(inline == true); return "ZmFrZQ==" end }
    gmInte = {
        getTranslation = function(_, fallback) return fallback end,
        getPlayerFormat = function() return { steamID64 = "76561198000000001" } end,
        chatAddText = function(_, message) notices[#notices + 1] = message end,
        log = function(message) logs[#logs + 1] = message end,
        api = { post = function(endpoint, body, success, failed)
            requests[#requests + 1] = { endpoint = endpoint, body = body, success = success, failed = failed }
        end },
    }
    loadGLua("lua/gmod_integration/modules/screenshots/cl_screenshots.lua")
end

local function frame(seconds)
    clock = clock + (seconds or 0)
    hooks["Think:gmInte:Screenshot:WaitForInterface"]()
    hooks["PostRender:gmInteScreenshot"]()
end

local function test(name, callback)
    reset()
    local ok, problem = pcall(callback)
    if ok then passed = passed + 1 else failures[#failures + 1] = name .. ": " .. tostring(problem) end
end

test("console command announces the wait and never captures an open console", function()
    consoleOpen = true
    commands.gmi_screen(nil, "gmi_screen", { "Evidence" })
    assert(#logs == 1 and logs[1]:find("Close the console", 1, true))
    assert(#notices == 1 and notices[1] == logs[1])
    frame(10)
    frame(10)
    assert(#captures == 0 and #requests == 0 and #notices == 1)
    consoleOpen = false
    frame()
    frame(0.49)
    assert(#captures == 0)
    frame(0.01)
    assert(#captures == 1 and #requests == 1 and requests[1].body.title == "Evidence")
    assert(requests[1].endpoint == "/clients/:steamID64/servers/:serverID/screenshots")
end)

test("Escape and context menus both postpone the image until the interface is clear", function()
    gameMenuOpen = true
    gmInte.takeScreenShot()
    frame(1)
    assert(#captures == 0)
    gameMenuOpen = false
    hooks["OnContextMenuOpen:gmInte:ContextScreen:ContextMenu:Open"]()
    frame(1)
    assert(#captures == 0)
    hooks["OnContextMenuClose:gmInte:ContextScreen:ContextMenu:Close"]()
    frame()
    frame(0.5)
    assert(#captures == 1 and #requests == 1)
end)

test("a menu reopening between Think and PostRender invalidates the ready frame", function()
    assert(gmInte.takeScreenShot("First"))
    clock = 0.5
    hooks["Think:gmInte:Screenshot:WaitForInterface"]()
    consoleOpen = true
    hooks["PostRender:gmInteScreenshot"]()
    assert(#captures == 0)
    consoleOpen = false
    frame()
    frame(0.5)
    assert(#captures == 1)
end)

test("duplicate commands preserve the accepted title while queued and while sending", function()
    commands.gmi_screen(nil, "gmi_screen", { "First", "title" })
    commands.gmod_integration_screen(nil, "gmod_integration_screen", { "Second" })
    frame(0.5)
    assert(#requests == 1 and requests[1].body.title == "First title")
    assert(gmInte.takeScreenShot("Third") == false)
    requests[1].success(200, {})
    assert(gmInte.takeScreenShot("Next"))
    frame(0.5)
    assert(#requests == 2 and requests[2].body.title == "Next")
end)

test("context requests share the same pending guard and do not retain an earlier title", function()
    gmInte.takeScreenShot("Earlier")
    frame(0.5)
    requests[1].success(200, {})
    hooks["OnContextMenuOpen:gmInte:ContextScreen:ContextMenu:Open"]()
    gmInte.contextScreenshot()
    gmInte.contextScreenshot()
    frame(1)
    assert(#requests == 1)
    hooks["OnContextMenuClose:gmInte:ContextScreen:ContextMenu:Close"]()
    frame()
    frame(0.5)
    assert(#requests == 2 and requests[2].body.title == "")
end)

test("failed captures retry three times then recover for a new request", function()
    captureResult = nil
    gmInte.takeScreenShot()
    for _ = 1, 4 do frame(0.5) end
    assert(#captures == 4 and #requests == 0 and gmInte.showScreenshotInfo == false)
    assert(notices[#notices]:find("Failed to take screenshot", 1, true))
    captureResult = "new-synthetic-image"
    assert(gmInte.takeScreenShot())
    frame(0.5)
    assert(#requests == 1)
end)

test("a relay error releases the busy state without retrying an already sent image", function()
    gmInte.takeScreenShot()
    frame(0.5)
    requests[1].failed(429, {})
    assert(notices[#notices]:find("rate limited", 1, true))
    frame(10)
    assert(#requests == 1)
    assert(gmInte.takeScreenShot())
end)

test("only a confirmed Discord acknowledgement announces a Discord delivery", function()
    gmInte.takeScreenShot()
    frame(0.5)
    assert(#notices == 0 and #requests == 1)
    requests[1].success(200, { success = true, saved = true, discordDelivered = true })
    assert(notices[1] == "Screenshot sent to Discord.")
    assert(gmInte.takeScreenShot())
end)

test("saved screenshots explain missing destinations and unconfirmed Discord delivery", function()
    for _, delivery in ipairs({ "not_configured", "unavailable" }) do
        reset()
        gmInte.takeScreenShot()
        frame(0.5)
        requests[1].success(200, { success = true, saved = true, discordDelivered = false, delivery = delivery })
        assert(notices[1]:find("saved in the web panel", 1, true))
        if delivery == "not_configured" then assert(notices[1]:find("No Discord screenshot channel", 1, true))
        else assert(notices[1]:find("could not be confirmed", 1, true)) end
        assert(not notices[1]:find("sent to Discord", 1, true))
        frame(10)
        assert(#requests == 1 and gmInte.takeScreenShot())
    end
end)

test("unconfirmed acknowledgements and non-rate-limit failures are visible without private details", function()
    for _, status in ipairs({ 200, 400, 503, 504 }) do
        reset()
        gmInte.takeScreenShot()
        frame(0.5)
        if status == 200 then requests[1].success(status, { success = true })
        else requests[1].failed(status, { error = "private token or report data" }) end
        assert(notices[1]:find("could not be sent or confirmed", 1, true))
        assert(not notices[1]:find("private token", 1, true))
        frame(10)
        assert(#requests == 1 and gmInte.takeScreenShot())
    end
end)

test("invalid titles are refused before queuing or rendering", function()
    assert(gmInte.takeScreenShot({}) == false)
    assert(gmInte.takeScreenShot(string.rep("x", 257)) == false)
    frame(1)
    assert(#captures == 0 and #requests == 0)
    assert(notices[1] == "Please use a shorter screenshot title.")
end)

test("only explicit chat command prefixes queue an image for the local player", function()
    local chat = hooks["OnPlayerChat:gmInteChatCommands"]
    chat(localPlayer, ".screen accidental", false, false)
    chat({}, "/screen other-player", false, false)
    frame(1)
    assert(#captures == 0)
    chat(localPlayer, "/screen Chat title", false, false)
    frame(0.5)
    assert(#requests == 1 and requests[1].body.title == "Chat title")
end)

if #failures > 0 then error(table.concat(failures, "\n")) end
print("Screenshot command regressions: " .. passed .. " passed")
