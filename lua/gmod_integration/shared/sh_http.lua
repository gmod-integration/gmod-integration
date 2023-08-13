//
// HTTP
//

// Variables
gmInte.api = 'https://api.gmod-integration.com/'
gmInte.defParams = "&version=" .. gmInte.version

// Functions
function gmInte.isCodeValid(code)
    // if first number is 2
    return string.sub(code, 1, 1) == "2"
end

function gmInte.httpError(error)
	gmInte.log("Web request failed")
	gmInte.log("Error details: "..error)
end

function gmInte.ulrGenerate(endpoint, parameters)
    local params = "="
    for k, v in pairs(parameters) do
        params = params .. "&" .. k .. "=" .. v
    end
    if SERVER then
        return gmInte.api .. endpoint .. "?" .. params .. gmInte.defParams .. "&id=" .. gmInte.config.id .. "&token=" .. gmInte.config.token
    else
        return gmInte.api .. endpoint .. "?" .. params .. gmInte.defParams
    end
end

function gmInte.fetch(endpoint, parameters, onSuccess)
    gmInte.log("Fetching " .. endpoint, true)
    http.Fetch(
        // URL
        gmInte.ulrGenerate(endpoint, parameters),
        // onSuccess
        function (body, length, headers, code )
            if gmInte.isCodeValid(code) then
                onSuccess(body, length, headers, code)
            else
                gmInte.httpError(body)
            end
        end,
        gmInte.httpError
    )
end

function gmInte.post(endpoint, parameters, data, onSuccess)
    local bodyData = util.TableToJSON(data)
    gmInte.log("Posting " .. endpoint, true)
    HTTP(
        {
            url = gmInte.ulrGenerate(endpoint, parameters),
            method = "POST",
            headers = {
                ["Content-Type"] = "application/json",
                ["Content-Length"] = tostring(#bodyData),
            },
            body = bodyData,
            type = "application/json",
            success = function(code, body, headers)
                if (gmInte.isCodeValid(code)) then
                    if (onSuccess) then
                        onSuccess(body, length, headers, code)
                    end
                else
                    gmInte.httpError(body)
                end
            end,
            failed = gmInte.httpError,
        }
    )
end

function gmInte.simplePost(request_id, data, onSuccess)
    gmInte.post(
        "",
        {
            request = request_id
        },
        data,
        function( body, length, headers, code )
            if (onSuccess) then
                onSuccess(body, length, headers, code)
            end
        end
    )
end

function gmInte.simpleFetch(request_id, onSuccess)
    gmInte.fetch(
        "",
        {
            request = request_id
        },
        function( body, length, headers, code )
            if (onSuccess) then
                onSuccess(body, length, headers, code)
            end
        end
    )
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
    // Parameters
    { request = "requ" },
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