_ = require 'underscore'

class Route

  apiVersion: '/api/1/'

  constructor: (@resource, @app, @config) ->
    @rname = @resource.lname
    @name = @rname + 's'

    if @rname[@rname.length - 1] is 'y'
      @name = @rname[...-1] + 'ies'

    @Config()

  _Add: (type, url, middle..., done) ->
    if not done?
      done = url
      url = '/'

    if not middle.length and typeof(url) is 'function'
      middle.push url
      url = '/'

    if not @[type + url]?
      @[type + url] = done

      #FIXME: code clarity
      if middle.length
        middle.push (req, res, next) => @[type + url](req, res, next)
        @app.route(@apiVersion + @name + url)[type].apply @app.route(@apiVersion + @name + url), middle
      else
        @app.route(@apiVersion + @name + url)[type] (req, res, next) => @[type + url](req, res, next)

    else
      @[type + url] = done

  for verb in ['All', 'Get', 'Post', 'Put', 'Delete']
    do (verb) =>
      @::[verb] = (args...) ->
        args.unshift (verb[0].toLowerCase() + verb[1..])
        @_Add.apply @, args

  Config: ->

class SingleRoute extends Route

  constructor: (@resource, @app, @config) ->
    @rname = @resource.lname
    @name = @rname

    #Resource creation if non-existant
    @resource.Fetch 1, (err, result) =>
      if err? and @resource.config?.schema? and _(@resource.config.schema).filter((item) -> not item.default? and not item.optional?).length
        throw new Error 'SingleRoute used with schema Resource and non existant row at id = 1. Please add it manualy to your DB system before continuing.'

      if err?
        @resource.Create {}, (err, res) ->
          return res.status(500).send(err) if err?

    @Config()

  Config: ->
    @All (req, res, next) =>
      @resource.Fetch 1, (err, result) =>
        return res.status(500).send(err) if err?

        @instance = result

        next()

    @Get (req, res, next) =>
      res.status(200).send @instance.ToJSON()

    @Put (req, res) =>
      _(@instance).extend req.body

      @instance.Save (err) =>
        return res.status(500).send(err) if err?

        res.status(200).send @instance.ToJSON()

class MultiRoute extends Route

  Config: ->
    @All '/:id*', (req, res, next) =>
      if not isFinite req.params.id
        return next()

      @resource.Fetch req.params.id, (err, result) =>
        return res.status(500).send(err) if err?

        @instance = result

        next()

    @Get (req, res) =>
      @resource.List (err, results) ->
        return res.status(500).send(err) if err?

        res.status(200).send _(results).invoke 'ToJSON'

    @Get '/:id', (req, res) =>
      res.status(200).send @instance.ToJSON()

    @Post (req, res) =>
      @resource.Deserialize req.body, (err, result) ->
        return res.status(500).send(err) if err?

        result.Save (err) ->
          return res.status(500).send(err) if err?

          res.status(200).send result.ToJSON()

    @Put '/:id', (req, res) =>
      _(@instance).extend req.body

      @instance.Save (err) =>
        return res.status(500).send(err) if err?

        res.status(200).send @instance.ToJSON()

    @Delete '/:id', (req, res) =>
      @instance.Delete (err) ->
        return res.status(500).send(err) if err?

        res.status(200).end()

class DefaultRoute extends Route
  constructor: ->
    throw new Error 'Deprecated: Route.DefaultRoute. Use Route.MultiRoute instead.'

Route.SingleRoute = SingleRoute
Route.MultiRoute = MultiRoute
Route.DefaultRoute = DefaultRoute
module.exports = Route