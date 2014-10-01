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

    if @config? and @config.empty
      return

    @Add 'all', '/:id*', restrict: false, (req, res, next) =>
      @Resource.Fetch req.params.id, (err, result) ->
        return res.status(500).send(err) if err?

        req[resName] = result
        next()

    @Add 'get', '', @config, (req, res) =>
      @Resource.List (err, results) ->
        return res.status(500).send(err) if err?

        res.status(200).send _(results).invoke 'ToJSON'

    @Add 'get', '/:id', @config, (req, res) ->
      res.status(200).send req[resName].ToJSON()

    @Add 'post', '', @config, (req, res) =>
      @Resource.Deserialize req.body, (err, result) ->
        return res.status(500).send(err) if err?

        result.Save (err) ->
          return res.status(500).send(err) if err?

          res.status(200).send result.ToJSON()

    @Add 'put', '/:id', @config, (req, res) ->
      _(req[resName]).extend req.body

      req[resName].Save (err) ->
        return res.status(500).send(err) if err?

        res.status(200).send req[resName].ToJSON()

    @Add 'delete', '/:id', @config, (req, res) ->
      req[resName].Delete (err) ->
        return res.status(500).send(err) if err?

        res.status(200)

  Add: (type, url, config, done) ->
    if !(done?)
      done = config
      config = @config

    done = @_MatchWrap type, config, done

    @app.route(@apiVersion + @resName + url)[type] done

  _MatchWrap: (type, config, done) ->
    if config? and config.restrict?
      if config.restrict is 'auth'
        done = @_WrapDoneAuth done
      else if config.restrict is 'user' and type isnt 'post'
        throw new Error 'Restricted \'user\' needs to be on account resource config' if not @account?
        done = @_WrapDoneUser done
      else if typeof config.restrict is 'object'
        done = @_WrapDoneObject config.restrict, done

    done

  _WrapDoneUser: (done) ->
    newUserDone = (req, res, next) =>
      return done req, res, next if not req.params.id?
      return res.status(403) if !(req.user?) or req.user.id isnt parseInt(req.params.id, 10)

      done req, res, next

  _WrapDoneAuth: (done) ->
    newAuthDone = (req, res, next) ->
      return res.status(403) if !(req.user?)

      done req, res, next

  _WrapDoneObject: (obj, done) ->
    newDone = (req, res, next) ->
      for key, val of obj
        return res.status(403) if not req.user? or not req.user[key]? or req.user[key] isnt val

      done req, res, next

module.exports = Route
