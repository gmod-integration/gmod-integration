//
// Functions
//

function gmInte.httpError(error)
	gmInte.log("Web request failed")
	gmInte.log("Error details: "..error)
end

//
// HTTP
//

local function sendHTTP(params)
    gmInte.log("HTTP Request: " .. params.method .. " " .. params.endpoint, true)
    gmInte.log("HTTP Body: " .. (params.body or "No body"), true)
    HTTP({
        url = "https://api.gmod-integration.com" .. params.endpoint,
        method = params.method,
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = params.body and string.len(params.body) or 0,
            ["id"] = gmInte.config.id,
            ["token"] = gmInte.config.token,
            ["version"] = gmInte.version
        },
        body = params.body && params.body or "",
        type = "application/json",
        success = function(code, body, headers)
            gmInte.log("HTTP Response: " .. code, true)
            gmInte.log("HTTP Body: " .. body, true)
            if (string.sub(code, 1, 1) == "2") then
                params.success && params.success(body, code, headers)
            else
                gmInte.httpError(body)
            end
        end,
        failed = gmInte.httpError,
    })
end

function gmInte.get(endpoint, onSuccess)
    sendHTTP({
        endpoint = endpoint,
        method = "GET",
        success = onSuccess
    })
end

function gmInte.post(endpoint, data, onSuccess)
    sendHTTP({
        endpoint = endpoint,
        method = "POST",
        body = util.TableToJSON(data),
        success = onSuccess
    })
end

function gmInte.put(endpoint, data, onSuccess)
    sendHTTP({
        endpoint = endpoint,
        method = "PUT",
        body = util.TableToJSON(data),
        success = onSuccess
    })
end

function gmInte.delete(endpoint, onSuccess)
    sendHTTP({
        endpoint = endpoint,
        method = "DELETE",
        success = onSuccess
    })
end

/*
// Fetch Example
gmInte.fetch(
    // Endpoint
    "",
    // Parameters
    { request = "requ" },
    // onSuccess
    function( body, length, headers, code )
        print(body)
    end
)

// Post Example
gmInte.post(
    // Endpoint
    "",
    // Data
    {
        data = "data"
    },
    // onSuccess
    function( body, length, headers, code )
        print(body)
    end
)
*/