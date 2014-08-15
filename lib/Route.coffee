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

  constructor: (@app, resName, @Resource, @config) ->
    @resName = resName + 's'

    # console.log @config

    if @config? and @config.account?
      @account = new Account @app, resName, @Resource, @config

    @Add 'all', '/:id*', @config, (req, res, next) =>
      @Resource.Fetch req.params.id, (err, result) ->
        return res.send 500, err if err?

        req[resName] = result
        next()

    @Add 'get', '', @config, (req, res) =>
      @Resource.List (err, results) ->
        return res.send 500, err if err?

        res.send 200, _(results).invoke 'ToJSON'

    @Add 'get', '/:id', @config, (req, res) ->
      res.send 200, req[resName].ToJSON()

    @Add 'post', '', @config, (req, res) =>
      @Resource.Deserialize req.body, (err, result) ->
        return res.send 500, err if err?

        result.Save (err) ->
          return res.send 500, err if err?

          res.send 200, result.ToJSON()

    @Add 'put', '/:id', @config, (req, res) ->
      _(req[resName]).extend req.body

      req[resName].Save (err) ->
        return res.send 500, err if err?

        res.send 200, req[resName].ToJSON()

    @Add 'delete', '/:id', @config, (req, res) ->
      req[resName].Delete (err) ->
        return res.send 500, err if err?

        res.send 200

  Add: (type, url, config, done) ->
    if !(done?)
      done = config
      config = @config

    if config? and config.restrict?
      if config.restrict is 'auth' and type isnt 'post'
        done = @WrapDoneAuth done
      else if config.restrict is 'user' and type isnt 'post'
        throw new Error 'Restricted \'user\' needs to be on account resource' if not @account?
        done = @WrapDoneUser done
      else if typeof config.restrict is 'object'
        done = @WrapDoneObject config.restrict, done

    @app[type] @apiVersion + @resName + url, done

  WrapDoneUser: (done) ->
    newUserDone = (req, res, next) =>
      return done req, res, next if not req.params.id?
      return res.send 403 if !(req.user?) or req.user.id isnt parseInt(req.params.id, 10)

      done req, res, next

  WrapDoneAuth: (done) ->
    newAuthDone = (req, res, next) ->
      return res.send 403 if !(req.user?)

      done req, res, next

  WrapDoneObject: (obj, done) ->
    newDone = (req, res, next) ->
      for key, val of obj
        return res.send 403 if not req.user? or not req.user[key]? or req.user[key] isnt val

      done req, res, next

module.exports = Route
