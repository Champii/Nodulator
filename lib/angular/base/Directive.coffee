Directive = (name, injects) ->

  class _Directive extends Base name, injects

    constructor: ->
      app.directive.apply app, super()

    _Body: (args...) ->

      super args[0]

      dir = {

        restrict: 'E'

        replace: true

        templateUrl: @_name + '-tpl'

        link: (@scope, @element, @attr) =>
          @_Init() if @_Init?
          @scope[name] = elem for name, elem of @ when name[0] isnt '_'

      }


      dir
