function gmInte.sendToAPI(endpoint, method, data, onSuccess, onFailed)
  return gmInte.api.requestAPI({
    ["endpoint"] = endpoint,
    ["method"] = method,
    ["body"] = data,
    ["success"] = onSuccess,
    ["failed"] = onFailed
  })
end
