Directive = (name, injects) ->

  class _Directive

    constructor: ->
      if not name?
        return console.error 'Modulator.Directive must have a name'

      @_name = name
      @_injects = injects

      app.directive @_name, @_injects.concat [(args...) => @_Body.apply @, args]

    _Body: (args...) ->

      dir = {

        restrict: 'E'

        replace: true

        templateUrl: @_name + '-tpl'

        link: (@scope, @element, @attr) =>
          @Init() if @Init?
          @scope[name] = elem for name, elem of @ when name[0] isnt '_' and name isnt 'Init'

      }

      for arg, i in args
        @[injects[i]] = arg

      return dir

    _Link: ->
      return console.error 'Link not implemented for Directive ', @_name,

