Directive = (name, injects) ->

  class _Directive extends Base name, injects

    constructor: ->
      console.log 'Constructor', name, injects, app
      app.directive 'test', super()[1]
      console.log 'Constructor', name, injects, app
      @
      # app.directive.apply app, super()

    _Body: (args) ->

      super args

      dir = {

        restrict: 'E'

        replace: true

        templateUrl: @_name + '-tpl'

        link: (@scope, @element, @attr) =>
          @_Init() if @_Init?
          @scope[name] = elem for name, elem of @ when name[0] isnt '_'
          console.log 'scope', @scope

      }


      dir
