Directive = (name, injects) ->

  class _Directive extends Base name, injects

    constructor: ->
      app.directive.apply app, super()

    _Body: (args) ->

      super args

      dir = {

        restrict: 'E'

        replace: true

        templateUrl: @_name + '-tpl'

      }
      if @Pre? or @Post?
        dir.compile = =>
          res = {}
          if @Pre?
            res.pre = (@scope, @element, @attr) =>
              @Pre() if @Pre?
              @scope[name] = elem for name, elem of @ when name[0] isnt '_'
          if @Post?
            res.post = (@scope, @element, @attr) =>
              @Post() if @Post?
              @scope[name] = elem for name, elem of @ when name[0] isnt '_'
          return res
      else
        dir.link = (@scope, @element, @attr) =>
          @_Init() if @_Init?
          @scope[name] = elem for name, elem of @ when name[0] isnt '_'

      dir
