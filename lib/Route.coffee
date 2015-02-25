_ = require 'underscore'

class Route
  apiVersion: '/api/1/'

  constructor: (@resource, @app, @config) ->
    @name = @resource.lname + 's'

    @Config()

  _Add: (type, url, middle..., done) ->
    if not done?
      done = url
      url = '/'

    if not middle.length and typeof(url) is 'function'
      middle.push url
      url = '/'

    done = @_AddMiddleware type, url, done

    if not @[type + url]?
      @[type + url] = done
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

  _AddMiddleware: (type, url, done) ->
    if !@config?
      return done

    for element, content of @config
      if typeof content is 'function'
        done = content done
      else if typeof content is 'object' and not content.prototype
        for method, wrapper of content
          if method == type
            done = wrapper done
          else
            method = method.split('-')
            if method.length > 1
              if method[0] == type and method[1] == url
                done = wrapper done
            else if method[0] == type
              done = wrapper done

    done

  Config: ->

class DefaultRoute extends Route
  Config: ->
    @All '/:id*', (req, res, next) =>
      if not isFinite req.params.id
        return next()

      @resource.Fetch req.params.id, (err, result) =>
        return res.status(500).send(err) if err?

        if not req.resources?
          req.resources = {}

        req.resources[@resource.lname] = result
        next()

    @Get (req, res) =>
      @resource.List (err, results) ->
        return res.status(500).send(err) if err?

        res.status(200).send _(results).invoke 'ToJSON'

    @Get '/:id', (req, res) =>
      res.status(200).send req.resources?[@resource.lname]?.ToJSON()

    @Post (req, res) =>
      @resource.Deserialize req.body, (err, result) ->
        return res.status(500).send(err) if err?

        result.Save (err) ->
          return res.status(500).send(err) if err?

          res.status(200).send result.ToJSON()

    @Put '/:id', (req, res) =>
      _(req.resources[@resource.lname]).extend req.body

      req.resources[@resource.lname].Save (err) =>
        return res.status(500).send(err) if err?

        res.status(200).send req.resources[@resource.lname].ToJSON()


    @Delete '/:id', (req, res) =>
      req.resources[@resource.lname].Delete (err) ->
        return res.status(500).send(err) if err?

        res.status(200).end()

Route.DefaultRoute = DefaultRoute
module.exports = Route
