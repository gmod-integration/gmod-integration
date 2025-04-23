function gmInte.sendToAPI(endpoint, method, data, onSuccess, onFailed)
  gmInte.http.requestAPI({
    ["endpoint"] = endpoint,
    ["method"] = method,
    ["body"] = data,
    ["success"] = onSuccess,
    ["failed"] = onFailed
  })
end