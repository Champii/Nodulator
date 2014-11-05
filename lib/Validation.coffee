# Takes a dict that describes what validation apply on what
# field : [validator, ...]
validation = (config) ->
  (done) ->
    (req, res, next) ->
      for field, validators of config
        for validator in validators
          if !validator(req[field])
            return error 400, field + "malformed " + '# FIXME : get validator err'
      done req, res, next
