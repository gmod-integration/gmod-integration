local apiVersion = "v3"
local apiFQDN = "api.gmod-integration.com"
local apiDevFQDN = "dev-api.gmod-integration.com"

gmInte.http = gmInte.http || {}

//
// HTTP
//

local function getAPIURL(endpoint)
    local url = "https://" .. (gmInte.config.devInstance && apiDevFQDN || apiFQDN) .. "/" .. apiVersion

    if (SERVER) then
        url = url .. "/servers/" .. gmInte.config.id
    else
        if (string.sub(endpoint, 1, 8) == "/users") then
            return url .. endpoint
        end

        url = url .. "/clients/" .. LocalPlayer():SteamID64()
    end

    return url .. endpoint
end

local function showableBody(endpoint)
    // if start with /streams or /screenshots return false
    if (string.sub(endpoint, 1, 8) == "/streams" || string.sub(endpoint, 1, 12) == "/screenshots") then
        return false
    end

    return true
end

local function genRequestID()
    return "gmInte-" .. util.CRC(tostring(SysTime()))
end

function gmInte.http.requestAPI(params)
    local body = params.body && util.TableToJSON(params.body || {}) || ""
    local bodyLength = string.len(body)
    local token = params.token || gmInte.config.token || ""
    local url = getAPIURL(params.endpoint)
    local method = params.method
    local success = params.success || function() end
    local failed = params.failed || function() if (!gmInte.config.debug) then gmInte.log("HTTP Failed, if this error persists please contact support") end end
    local version = gmInte.config.version
    local showableBody = showableBody(params.endpoint)
    local requestID = genRequestID()

    local headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = bodyLength,
        ["Authorization"] = "Bearer " .. token,
        ["Version"] = version
    }
    local type = "application/json"

    // Log
    if (gmInte.config.devInstance) then gmInte.log("HTTP Using dev Instance", true) end
    gmInte.log("HTTP Request ID: " .. requestID, true)
    gmInte.log("HTTP Request: " .. method .. " " .. url, true)
    gmInte.log("HTTP Body: " .. (showableBody && body || "HIDDEN"), true)

    // Send
    HTTP({
        ["url"] = url,
        ["method"] = method,
        ["headers"] = headers,
        ["body"] = body,
        ["type"] = type,
        ["success"] = function(code, body, headers)
            // Log
            gmInte.log("HTTP Request ID: " .. requestID, true)
            gmInte.log("HTTP Response: " .. code, true)
            if (gmInte.config.debug) then gmInte.log("HTTP Body: " .. body, true) end

            // if not 2xx return failed
            if (code < 200 || code >= 300) then
                return failed(body, code, headers)
            end

            // if not application/json return failed
            if (string.sub(headers["Content-Type"], 1, 16) != "application/json") then
                gmInte.log("HTTP Failed: Invalid Content-Type", true)
                return failed({ ["error"] = "Invalid Content-Type" }, code, headers)
            end

            // Parse body
            body = util.JSONToTable(body || "{}")

            // Return success
            return success(code, body)
        end,
        ["failed"] = function(error)
            // Log
            gmInte.log("HTTP Request ID: " .. requestID, true)
            gmInte.log("HTTP Failed: " .. error, true)

            // Return failed
            return failed({ ["error"] = error })
        end
    })
end

//
// HTTP Methods
//

function gmInte.http.get(endpoint, onSuccess, onFailed)
    gmInte.http.requestAPI({
        ["endpoint"] = endpoint,
        ["method"] = "GET",
        ["success"] = onSuccess,
        ["failed"] = onFailed
    })
end

function gmInte.http.post(endpoint, data, onSuccess, onFailed)
    gmInte.http.requestAPI({
        ["endpoint"] = endpoint,
        ["method"] = "POST",
        ["body"] = data,
        ["success"] = onSuccess,
        ["failed"] = onFailed
    })
end

function gmInte.http.put(endpoint, data, onSuccess, onFailed)
    gmInte.http.requestAPI({
        ["endpoint"] = endpoint,
        ["method"] = "PUT",
        ["body"] = data,
        ["success"] = onSuccess,
        ["failed"] = onFailed
    })
end

function gmInte.http.delete(endpoint, onSuccess, onFailed)
    gmInte.http.requestAPI({
        ["endpoint"] = endpoint,
        ["method"] = "DELETE",
        ["success"] = onSuccess,
        ["failed"] = onFailed
    })
end