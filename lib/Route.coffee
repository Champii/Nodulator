_ = require 'underscore'

class Route
  apiVersion: '/api/1/'

  constructor: (@resource, @app, @config) ->
    @name = @resource.lname + 's'

    @Config()

  Add: (type, url, done) ->
    if not done?
      done = url
      url = '/'

    done = @_AddMiddleware type, url, done
    if not @[type + url]?
      @[type + url] = done
      @app.route(@apiVersion + @name + url)[type] (req, res, next) => @[type + url](req, res, next)
    else
      @[type + url] = done

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
    @Add 'all', '/:id*', (req, res, next) =>
      if not isFinite req.params.id
        console.log 'Not finite :', isFinite req.params.id
        return next()

      @resource.Fetch req.params.id, (err, result) =>
        return res.status(500).send(err) if err?

        req[@resource.lname] = result
        next()

    @Add 'get', (req, res) =>
      @resource.List (err, results) ->
        return res.status(500).send(err) if err?

        res.status(200).send _(results).invoke 'ToJSON'

    @Add 'get', '/:id', (req, res) =>
      res.status(200).send req[@resource.lname].ToJSON()

    @Add 'post', (req, res) =>
      @resource.Deserialize req.body, (err, result) ->
        return res.status(500).send(err) if err?

        result.Save (err) ->
          return res.status(500).send(err) if err?

          res.status(200).send result.ToJSON()

    @Add 'put', '/:id', (req, res) =>
      _(req[@resource.lname]).extend req.body

      req[@resource.lname].Save (err) =>
        return res.status(500).send(err) if err?

        res.status(200).send req[@resource.lname].ToJSON()


    @Add 'delete', '/:id', (req, res) =>
      req[@resource.lname].Delete (err) ->
        return res.status(500).send(err) if err?

        res.status(200).end()


Route.DefaultRoute = DefaultRoute
module.exports = Route
