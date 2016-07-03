Controller = (name, injects) ->

  class _Controller extends Base name, injects

    constructor: ->
      [name, inj] = super()
      app.controller name, inj
