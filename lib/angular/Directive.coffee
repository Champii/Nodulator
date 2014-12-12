Directive = (name, injects) ->

  class _Directive

    constructor: ->
      if not name?
        return console.error 'Modulator.Directive must have a name'
      @name = name
      @injects = injects

      app.directive @name, @injects.concat [(args...) => @Body.apply @, args]

    Body: (args...) ->
      for arg, i in args
        @[injects[i]] = arg

      return {

        restrict: 'E'

        replace: true

        templateUrl: @name + '-tpl'

        link: (@scope, @element, @attr) =>
          @Link()
      }

    Link: ->
      return console.error 'Link not implemented for directive ', @name,
