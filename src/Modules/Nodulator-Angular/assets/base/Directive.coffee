Directive = (name, injects) ->

  class _Directive extends Base name, injects

    constructor: ->
      @_dirExtended = []

      for item in @_injects when typeof(item) isnt 'string'
        @_dirExtended.push item

      _tmp = []
      for item in @_injects
        if typeof(item) is 'string'
          _tmp.push item

      @_injects = _tmp

      app.directive.apply app, super()

    _Body: (args) ->

      dir = {

        restrict: 'E'

        replace: true

        templateUrl: @_name + '-tpl'

      }

      for arg in @_dirExtended
        for key, item of arg
          dir[key] = item

      super args

      if @Pre? or @Post?
        dir.compile = =>
          res = {}
          if @Pre?
            res.pre = (@scope, @element, @attr) =>
              @Pre() if @Pre?
              @[name] = @scope[name] = elem for name, elem of @ when name[0] isnt '_'
          if @Post?
            res.post = (@scope, @element, @attr) =>
              @Post() if @Post?
              @[name] = @scope[name] = elem for name, elem of @ when name[0] isnt '_'
          return res
      else
        dir.link = (@scope, @element, @attr) =>
          @[name] = @scope[name] = elem for name, elem of @ when name[0] isnt '_'
          @_Init() if @_Init?

          # @Init() if @Init?

      dir
