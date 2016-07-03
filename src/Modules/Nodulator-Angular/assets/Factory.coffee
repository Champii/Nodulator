Factory = (name, injects) ->

  class _Factory extends Base name, injects

    constructor: ->
      app.factory.apply app, super()
