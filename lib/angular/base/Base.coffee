Base = (name, injects) ->

  class _Base

    _name: name
    _injects: injects

    constructor: ->
      if not name?
        return console.error 'Modulator.Base must have a name'

      return [@_name, @_injects.concat [(args...) => @_Body.apply @, [args]]]

    _Body: (args) ->
      for arg, i in args
        @[@_injects[i]] = arg

      @Init() if @Init?
      @

    @Init: ->
      thus = @
      new thus

