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

    # done = @_AddMiddleware type, url, done

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

  All: (args...) ->
    args.unshift 'all'
    @_Add.apply @, args

  Get: (args...) ->
    args.unshift 'get'
    @_Add.apply @, args

  Post: (args...) ->
    args.unshift 'post'
    @_Add.apply @, args

  Put: (args...) ->
    args.unshift 'put'
    @_Add.apply @, args

  Delete: (args...) ->
    args.unshift 'delete'
    @_Add.apply @, args

  Config: ->

class DefaultRoute extends Route
  Config: ->
    @All '/:id*', (req, res, next) =>
      if not isFinite req.params.id
        return next()

      @resource.Fetch req.params.id, (err, result) =>
        return res.status(500).send(err) if err?

        if not req.instances?
          req.instances = {}

        @instance = result

        #FIXME: deprecated, for retro compatibility only
        req.instances[@rname] = result

        next()

    @Get (req, res) =>
      @resource.List (err, results) ->
        return res.status(500).send(err) if err?

        res.status(200).send _(results).invoke 'ToJSON'

    @Get '/:id', (req, res) =>
      res.status(200).send req.instances?[@rname]?.ToJSON()

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

Route.DefaultRoute = DefaultRoute
module.exports = Route
