Service = (name, injects) ->

  class _Service extends Base name, injects

    constructor: ->
      [name, inj] = super()
      app.service name + 'Service', inj
