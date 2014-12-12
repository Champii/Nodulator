Service = (name, injects) ->

  class _Service

    constructor: ->
      if not name?
        return console.error 'Modulator.Service must have a name'

      @name = name
      @injects = injects

      app.service @name + 'Service', @injects.concat [(args...) => @Body.apply @, args]

    Body: (args...) ->

      # @ for name, func of @ when typeof func is 'function' and name not in ['Body', 'Link', '_Service']

      @[injects[i]] = arg for arg, i in args

      @
