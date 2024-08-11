local apiVersion = "v3"
gmInte.http = gmInte.http || {}
local function getAPIURL(endpoint)
    local method = gmInte.isPrivateIP(gmInte.config.apiFQDN) && "http" || "https"
    endpoint = string.gsub(endpoint, ":serverID", gmInte.config.id)
    if CLIENT then endpoint = string.gsub(endpoint, ":steamID64", LocalPlayer():SteamID64()) end
    return method .. "://" .. gmInte.config.apiFQDN .. "/" .. apiVersion .. endpoint
end

local function showableBody(endpoint)
    if string.sub(endpoint, 1, 8) == "/streams" || string.sub(endpoint, 1, 12) == "/screenshots" then return false end
    return true
end

local requestIndicator = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
function gmInte.http.requestAPI(params)
    local body = params.body && util.TableToJSON(params.body || {}) || ""
    local bodyLength = string.len(body)
    local token = params.token || gmInte.config.token || ""
    local url = getAPIURL(params.endpoint || "")
    local method = params.method || "GET"
    local success = params.success || function() end
    local failed = params.failed || function() end
    local version = gmInte.version || "Unknown"
    local actualSec = math.Round(SysTime()) % 10
    local localRequestID = util.CRC(tostring(SysTime()))
    requestIndicator[actualSec] = requestIndicator[actualSec] && requestIndicator[actualSec] + 1 || 1
    timer.Simple(10, function() requestIndicator[actualSec] = requestIndicator[actualSec] - 1 end)
    if token == "" then
        return failed(401, {
            ["error"] = "No token provided"
        })
    end

    local headers = {
        ["Content-Type"] = "application/json",
        ["Content-Length"] = bodyLength,
        ["Authorization"] = "Bearer " .. token,
        ["Gmod-Integrations-Version"] = version,
        ["Gmod-Integrations-Request-ID"] = localRequestID
    }

    gmInte.log("HTTP FQDN: " .. gmInte.config.apiFQDN, true)
    gmInte.log("HTTP Request ID: " .. localRequestID, true)
    gmInte.log("HTTP Request: " .. method .. " " .. url, true)
    gmInte.log("HTTP Body: " .. (showableBody(params.endpoint) && body || "HIDDEN"), true)
    HTTP({
        ["url"] = url,
        ["method"] = method,
        ["headers"] = headers,
        ["body"] = body,
        ["type"] = "application/json",
        ["success"] = function(code, body, headers)
            gmInte.log("HTTP Request ID: " .. localRequestID, true)
            gmInte.log("HTTP Response: " .. code, true)
            gmInte.log("HTTP Body: " .. body, true)
            if string.sub(headers["Content-Type"], 1, 16) != "application/json" then
                gmInte.log("HTTP Failed: Invalid Content-Type", true)
                return failed(code, body)
            end

            body = util.JSONToTable(body || "{}")
            if code < 200 || code >= 300 then
                gmInte.log("HTTP Failed: Invalid Status Code", true)
                return failed(code, body)
            end

            gmInte.aprovedCredentials = true
            return success(code, body)
        end,
        ["failed"] = function(error)
            gmInte.log("HTTP Request ID: " .. localRequestID, true)
            gmInte.log("HTTP Failed: " .. error, true)
        end
    })
end

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

local nextLogPacket = {}
function gmInte.http.postLog(endpoint, data)
    local requestAverage = 0
    for k, v in ipairs(requestIndicator) do
        requestAverage = requestAverage + v
    end

    requestAverage = requestAverage / 10
    if requestAverage >= 2 then
        local logPacketIndex = #nextLogPacket + 1
        table.insert(nextLogPacket, {
            ["endpoint"] = endpoint,
            ["data"] = data
        })

        timer.Simple(3, function()
            if #nextLogPacket == logPacketIndex then
                gmInte.http.requestAPI({
                    ["endpoint"] = "/servers/:serverID/logs",
                    ["method"] = "POST",
                    ["body"] = nextLogPacket
                })

                nextLogPacket = {}
            end
        end)
    else
        gmInte.http.requestAPI({
            ["endpoint"] = endpoint,
            ["method"] = "POST",
            ["body"] = data
        })
    end
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