error = (res, error_code, message) ->
  return res.status(error_code).send({"error" : message})
