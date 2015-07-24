_ = require \underscore
Route = require \./Route

class SingleRoute extends Route

  (@resource, @config) ->
    throw new Error 'SingleRoute constructor needs a Resource as first parameter' if not @resource? or typeof(@resource) isnt 'function'

    @rname = @resource.lname

    @name = @rname

    if @rname[@rname.length - 1] is 'y'
      @name = @rname[...-1] + 'ies'

    @app = Nodulator.app

    #Resource creation if non-existant
    @resource.Fetch 1, (err, result) ~>
      if err? and @resource.config?.schema? and
         _(@resource.config.schema).filter((item) ->
           not item.default? and not item.optional?).length
        throw new Error """
        SingleRoute used with schema Resource and non existant row at id = 1.
        Please add it manualy to your DB system before continuing.'
        """
      if err?
        @resource.Create {}, (err, res) ->
          return res.status(500).send(err) if err?

    @Config()

  Config: ->
    @All ~> it.SetInstance @resource.Fetch 1
    @Get ~> it.instance.ToJSON!
    @Put ~> it.instance.ExtendSafe req.body and it.instance._SaveUnwrapped!

module.extends = SingleRoute
