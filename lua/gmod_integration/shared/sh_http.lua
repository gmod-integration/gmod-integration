//
// Functions
//

function gmInte.isCodeValid(code)
    // if first number is 2
    return string.sub(code, 1, 1) == "2"
end

function gmInte.httpError(error)
	gmInte.log("Web request failed")
	gmInte.log("Error details: "..error)
end

//
// HTTP
//

local function sendHTTP(params)
    HTTP({
        url = "https://api.gmod-integration.com" .. params.endpoint,
        method = params.method,
        headers = {
            ["Content-Type"] = "application/json",
            ["Content-Length"] = tostring(#params.body),
            ["id"] = gmInte.config.id,
            ["token"] = gmInte.config.token,
            ["version"] = gmInte.version
        },
        body = params.body,
        type = "application/json",
        success = function(code, body, headers)
            if (gmInte.isCodeValid(code)) then
                if (params.success) then
                    params.success(code, body, headers)
                end
            else
                gmInte.httpError(body)
            end
        end,
        failed = gmInte.httpError,
    })
end

function gmInte.fetch(endpoint, onSuccess)
    gmInte.log("Fetching " .. endpoint, true)
    sendHTTP({
        endpoint = endpoint,
        method = "GET",
        success = onSuccess
    })
end

function gmInte.post(endpoint, data, onSuccess)
    gmInte.log("Posting " .. endpoint, true)
    sendHTTP({
        endpoint = endpoint,
        method = "POST",
        body = util.TableToJSON(data),
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