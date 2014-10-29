_ = require 'underscore'

module.exports =
  class Route
    apiVersion: '/api/1/'

    constructor: (resource, app, config) ->
      @resource = resource
      @name = resource.lname + 's'
      @app = app
      @config = config

      @add 'all', @all, '/:id*'
      @add 'get', @get
      @add 'get', @get_id,'/:id*'
      @add 'post', @post, ''
      @add 'put', @put, '/:id*'
      @add 'delete', @delete, '/:id*'

    add: (type, done, url = '') ->
#      console.log 'Routing : ' + @name + ' -> ' + type + ' ' + @apiVersion + @name + url
      done = @_addMiddleware type, done, url
      @app.route(@apiVersion + @name + url)[type] done

    _addMiddleware: (type, done, url) ->
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

    all: (req, res, next) =>
      @resource.Fetch req.params.id, (err, result) =>
        return res.status(500).send(err) if err?

        req['resource'] = @name
        req[@name] = result
        next()

    get: (req, res) =>
      @resource.List (err, results) ->
        return res.status(500).send(err) if err?

        res.status(200).send _(results).invoke 'ToJSON'

    get_id: (req, res) =>
      res.status(200).send req[@name].ToJSON()

    post: (req, res) =>
      @resource.Deserialize req.body, (err, result) ->
        return res.status(500).send(err) if err?

        result.Save (err) ->
          return res.status(500).send(err) if err?

          res.status(200).send result.ToJSON()

    put: (req, res) =>
      _(req[@name]).extend req.body

      req[@name].Save (err) =>
        return res.status(500).send(err) if err?

        res.status(200).send req[@name].ToJSON()

    delete: (req, res) =>
      req[@name].Delete (err) ->
        return res.status(500).send(err) if err?

        res.status(200).send()
