_ = require 'underscore'
async = require 'async'

Account = require './Account'

class Route

  routes:
    get: []
    post: []
    put: []
    del: []
  apiVersion: '/api/1/'

  constructor: (@app, resName, Resource, @config) ->
    @resName = resName + 's'

    # console.log @config

    if @config? and @config.account?
      @account = new Account @app, resName, Resource, @config

    @Add 'all', '/:id*', @account?, (req, res, next) ->
      Resource.Fetch req.params.id, (err, result) ->
        return res.send 500, err if err?

        req[resName] = result
        next()

    @Add 'get', '', false, (req, res) ->
      Resource.List (err, results) ->
        return res.send 500, err if err?

        res.send 200, _(results).invoke 'ToJSON'

    @Add 'get', '/:id', (req, res) ->
      res.send 200, req[resName].ToJSON()

    @Add 'post', '', @account?, (req, res) ->
      Resource.Deserialize req.body, (err, result) ->
        return res.send 500, err if err?

        result.Save (err) ->
          return res.send 500, err if err?

          res.send 200, result.ToJSON()

    @Add 'put', '/:id', (req, res) ->
      _(req[resName]).extend req.body

      req[resName].Save (err) ->
        return res.send 500, err if err?

        res.send 200, req[resName].ToJSON()

    @Add 'delete', '/:id', (req, res) ->
      req[resName].Delete (err) ->
        return res.send 500, err if err?

        res.send 200

  Add: (type, url, registrated, done) ->
    if !(done?)
      done = registrated
      registrated = false

    if registrated and @account?
      done = @account.WrapDone done

    @app[type] @apiVersion + @resName + url, done


module.exports = Route
