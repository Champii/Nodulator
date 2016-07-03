Base = (name, injects) ->

  class _Base

    _name: name
    _injects: injects

    constructor: ->
      if not name?
        return console.error 'N.Base must have a name'

      for arg, i in @_injects when typeof(arg) is 'string'
        service = arg.slice 0, arg.search /Service$/g
        if not (service in (key for key, val of Nodulator.services)) and service in _resources
          Nodulator.ResourceService(service).Init()

      return [@_name, @_injects.concat [(args...) => @_Body.apply @, [args]]]

    _Body: (args) ->
      for arg, i in args when typeof(@_injects[i]) is 'string'
        @[@_injects[i]] = arg

      @Init() if @Init?
      @

    @Init: ->
      thus = @
      new thus
