Base = (name, injects) ->

  class _Base

    _name: name
    _injects: injects

    constructor: ->
      if not name?
        return console.error 'Modulator.Base must have a name'

      if typeof @_injects is 'string'
        @_injects = [@_injects]

      console.log 'Injects', @_injects
      return [@_name, @_injects.concat [(args...) => @_Body.apply @, args]]

    _Body: (args) ->
      @[@_injects[i]] = arg for arg, i in args

      console.log 'Body', @
      @Init() if @Init?
      @

    @Init: ->
      thus = @
      document.addEventListener "DOMContentLoaded", (event) ->
        new thus
