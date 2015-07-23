_ = require 'underscore'
Nodulator = null
require! \prelude-ls : {each}

class Route

  basePath: '/api/'
  apiVersion: 1
  rname: ''

  (@resource, @config) ->
    Nodulator := require '../' if not Nodulator?

    if typeof(@resource) is 'function'
      @rname = @resource.lname
    else if typeof(@resource) is 'string'
      @rname = @resource
      @resource = undefined
      Nodulator.Config() if not Nodulator.config?
    else
      throw new Error 'Route constructor needs a Resource or a Name as first parameter'

    @name = @rname + 's'

    if @rname[@rname.length - 1] is 'y'
      @name = @rname[ til @name.length] + 'ies'

    @app = Nodulator.app
    @Config()

  _Add: (type, url, ...middle, done) ->
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
        middle.push (req, res, next) ~> @[type + url](req, res, next)
        @app.route(@basePath + @apiVersion + '/' + @name + url)[type].apply @app.route(@basePath + @apiVersion + '/' + @name + url), middle
      else
        @app.route(@basePath + @apiVersion + '/' + @name + url)[type] (req, res, next) ~>
          @[type + url](req, res, next)

    else
      @[type + url] = done

  _set = (verb) ~>
    @::[verb] = (...args) ->
      args.unshift verb[0].toLowerCase() + verb[1 til verb.length].join('')
      @_Add.apply @, args


  each _set, <[ All Get Post Put Delete ]>

  Config: ->

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
    @All (req, res, next) ~>
      @resource.Fetch 1, (err, result) ~>
        return res.status(500).send(err) if err?

        @instance = result

        next()

    @Get (req, res, next) ~>
      res.status(200).send @instance.ToJSON()

    @Put (req, res) ~>
      @instance.ExtendSafe req.body

      @instance._SaveUnwrapped (err) ~>
        return res.status(500).send(err) if err?

        res.status(200).send @instance.ToJSON()

class MultiRoute extends Route

  Config: ->
    @All '/:id*', (req, res, next) ~>
      if not isFinite req.params.id
        return next()

      @resource.Fetch +req.params.id, (err, result) ~>
        return res.status(500).send(err) if err?

        @instance = result

        next()

    @Get (req, res) ~>
      @resource.List req.query, (err, results) ~>
        return res.status(500).send {err: err} if err?

        res.status(200).send _(results).invoke 'ToJSON'

    @Get '/:id', (req, res) ~>
      res.status(200).send @instance.ToJSON()

    @Post (req, res) ~>
      # console.log 'Post', @resource.name, @resource
      @resource.Create req.body, (err, result) ->
        return res.status(500).send(err) if err?

        res.status(200).send result.ToJSON()

    @Put '/:id', (req, res) ~>
      @instance.ExtendSafe req.body

      @instance._SaveUnwrapped (err) ~>
        return res.status(500).send(err) if err?

        res.status(200).send @instance.ToJSON()

    @Delete '/:id', (req, res) ~>
      @instance._DeleteUnwrapped (err) ->
        return res.status(500).send(err) if err?

        res.status(200).end()

class DefaultRoute extends Route
  constructor: ->
    throw new Error 'Deprecated: Route.DefaultRoute. Use Route.MultiRoute instead.'

Route.SingleRoute = SingleRoute
Route.MultiRoute = MultiRoute
Route.DefaultRoute = DefaultRoute
module.exports = Route
