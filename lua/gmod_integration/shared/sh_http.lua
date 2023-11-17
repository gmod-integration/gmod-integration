//
// HTTP
//

local failMessage = {
    ["401"] = "Bad Credentials",
    ["403"] = "Forbidden",
    ["404"] = "Not Found",
    ["500"] = "Internal Server Error",
    ["503"] = "Service Unavailable",
    ["504"] = "Gateway Timeout",
}

local function errorMessage(body, code)
    if (body && body.error) then
        if (failMessage[code]) then
            return failMessage[code]
        else
            return body.error
        end
    elseif (failMessage[code]) then
        return failMessage[code]
    else
        return code
    end
end

local function sendHTTP(params)
    // Log the HTTP request
    gmInte.log("HTTP Request: " .. params.method .. " " .. params.endpoint, true)
    gmInte.log("HTTP Body: " .. (params.body || "No body"), true)

    // Send the HTTP request
    HTTP({
        url = "https://api.gmod-integration.com" .. params.endpoint,
        method = params.method,
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = params.body && string.len(params.body) || 0,
            ["id"] = gmInte.config.id,
            ["token"] = gmInte.config.token,
            ["version"] = gmInte.version
        },
        body = params.body && params.body || "",
        type = "application/json",
        success = function(code, body, headers)
            // Log the HTTP response
            gmInte.log("HTTP Response: " .. code, true)
            if (gmInte.debug) then gmInte.log("HTTP Body: " .. body, true) end

            // if body and is json extract it
            if (body && string.sub(headers["Content-Type"], 1, 16) == "application/json") then
                body = util.JSONToTable(body)
            end

            // Check if the request was successful
            if (string.sub(code, 1, 1) == "2") then
                if (params.success) then
                    params.success(code, body, headers)
                else
                    gmInte.log("HTTP Request Successful", true)
                end
            else
                if (params.failed) then
                    params.failed(code, body, headers)
                else
                    gmInte.logError(errorMessage(body, code))
                end
            end
        end,
        failed = function(error)
            gmInte.logError(error)
        end
    })
end

function gmInte.get(endpoint, onSuccess, onFailed)
    sendHTTP({
        endpoint = endpoint,
        method = "GET",
        success = onSuccess,
        failed = onFailed
    })
end

function gmInte.post(endpoint, data, onSuccess, onFailed)
    sendHTTP({
        endpoint = endpoint,
        method = "POST",
        body = util.TableToJSON(data),
        success = onSuccess,
        failed = onFailed
    })
end

function gmInte.put(endpoint, data, onSuccess, onFailed)
    sendHTTP({
        endpoint = endpoint,
        method = "PUT",
        body = util.TableToJSON(data),
        success = onSuccess,
        failed = onFailed
    })
end

function gmInte.delete(endpoint, onSuccess, onFailed)
    sendHTTP({
        endpoint = endpoint,
        method = "DELETE",
        success = onSuccess,
        failed = onFailed
    })
end