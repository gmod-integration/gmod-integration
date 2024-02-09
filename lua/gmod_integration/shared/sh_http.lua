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
        if (string.sub(endpoint, 1, 8) == "/players" || string.sub(endpoint, 1, 7) == "/errors") then
            return url .. endpoint
        end

        url = url .. "/clients/" .. LocalPlayer():SteamID64()
    end

    return url .. endpoint
end

function gmInte.http.requestAPI(params)
    local body = params.body || ""
    local bodyLength = string.len(body)
    local token = params.token || gmInte.config.token || ""
    local url = getAPIURL(params.endpoint)
    local method = params.method
    local success = params.success || function() end
    local failed = params.failed || function(error) gmInte.logError(error.error || error) end
    local version = gmInte.config.version

    local headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = bodyLength,
        ["Authorization"] = "Bearer " .. token,
        ["Version"] = version
    }
    local type = "application/json"

    // Log
    if (gmInte.config.devInstance) then gmInte.log("HTTP Using dev Instance", true) end
    gmInte.log("HTTP Request: " .. method .. " " .. url, true)
    gmInte.log("HTTP Body: " .. body, true)

    // Send
    HTTP({
        ["url"] = url,
        ["method"] = method,
        ["headers"] = headers,
        ["body"] = body,
        ["type"] = type,
        ["success"] = function(code, body, headers)
            // Log
            gmInte.log("HTTP Response: " .. code, true)
            if (gmInte.config.debug) then gmInte.log("HTTP Body: " .. body, true) end

            // if not 2xx return failed
            if (code < 200 || code >= 300) then
                return failed(body, code, headers)
            end

            // if not application/json return failed
            if (string.sub(headers["Content-Type"], 1, 16) != "application/json") then
                return failed({ ["error"] = "Invalid Content-Type" }, code, headers)
            end

            // Tableify the body if it's JSON
            body = util.JSONToTable(body || "{}")

            // Return success
            return success(body)
        end,
        ["failed"] = function(error)
            gmInte.logError(error)
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
        ["body"] = util.TableToJSON(data),
        ["success"] = onSuccess,
        ["failed"] = onFailed
    })
end

function gmInte.http.put(endpoint, data, onSuccess, onFailed)
    gmInte.http.requestAPI({
        ["endpoint"] = endpoint,
        ["method"] = "PUT",
        ["body"] = util.TableToJSON(data),
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