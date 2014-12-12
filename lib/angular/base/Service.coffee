Service = (name, injects) ->

  class _Service extends Base name, injects

    constructor: ->
      test = super()
      console.log 'Service test', test
      name = test[0]
      inj = test[1]
      app.service name + 'Service', inj
