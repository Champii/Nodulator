_ = require 'underscore'
async = require 'async'
cookieParser = require 'cookie-parser'
passport = require 'passport'

LocalStrategy = require('passport-local').Strategy

module.exports = (Nodulator) ->

  Nodulator.authApp = true
  Nodulator.passport = passport

  # Init
  do ->

    if not Nodulator.app?
      Nodulator.Route._InitServer()

    Nodulator.app.use Nodulator.passport.initialize()
    Nodulator.app.use Nodulator.passport.session()

  class AccountResource extends Nodulator.Resource '_account', {abstract: true}

    @userField:
      usernameField: 'username'
      passwordField: 'password'

    @_InitPassport: ->

      Nodulator.passport.serializeUser (user, done) =>
        done null, user.id

      Nodulator.passport.deserializeUser (id, done) =>
        @Fetch id, (err, user) ->
          return done null, false if err? and err.status is 'not_found'
          return done 'Error deserialize user', null if err?
          done null, user

      Nodulator.passport.use new LocalStrategy @userField, (username, password, done) =>
        constraints = {}
        constraints[@userField.usernameField] = username
        @Fetch constraints, (err, user) =>
        # @[@methodName] username, (err, user) =>
          return done err if err? and err.status isnt 'not_found'
          return done null, false, {message: 'Incorrect Username/password'} if err? or !(user?) or user[@userField.passwordField] isnt password
          return done null, user

    @_InitRoutes: (resName) ->
      @app.post '/api/1/' + resName + 's' + '/login', Nodulator.passport.authenticate('local'), (req, res) =>
        if @config? and @config.loginCallback?
          @config.loginCallback req, ->
            res.sendStatus(200)
        else
          res.sendStatus(200)

      @app.post '/api/1/' + resName + 's' + '/logout', (req, res) =>
        if @config? and @config.logoutCallback?
          @config.logoutCallback req, ->
            req.logout()
            res.sendStatus(200)
        else
          req.logout()
          res.sendStatus(200)

    @_InjectUser: (req, res) ->
      userObject = '<script>var __user = ' + (JSON.stringify(req.user?.ToJSON() || {})) + ';</script>\n'

      #FIXME: dirty
      userObject

    ToJSON: ->
      blob = super()
      delete blob[AccountResource.userField.passwordField]
      blob

  AccountResource.Init()

  if Nodulator.assets?
    Nodulator.ExtendBeforeRender AccountResource._InjectUser

    Nodulator.ExtendAfterRender (req, res) =>
      rend = 'auth'
      if req.user?
        rend = 'index'

      res.render rend

      # Returning false breaks the render loop
      return false

  Nodulator.AccountResource = (args...) ->
    if @resources[args[0]]?
      return @resources[args[0]]

    res = AccountResource.Extend.apply AccountResource, args

    if res.config? and res.config.fields?
      res.userField = res.config.fields

    res._InitPassport()
    res._InitRoutes args[0]

    res

  Nodulator.AccountResource._AccountResource = AccountResource

  Nodulator.Route.Auth = () ->
    (req, res, next) ->
      return res.sendStatus(403) if not req.user?

      next()

  Nodulator.Route.HasProperty = (obj) ->
    (req, res, next) =>
      return res.sendStatus(403) if not req.user?

      for key, item of obj
        if not req.user[key]? or req.user[key] isnt item
          return res.sendStatus(403)

      next()

  Nodulator.Route.IsOwn = (key) ->
    (req, res, next) =>
      return next() if not req.params[key]?
      return res.sendStatus(403) if not req.user?
      return res.sendStatus(403) if parseInt(req.params[key]) isnt req.user.id

      next()

  # Nodulator.Route.IsOwnObject = (key) ->
  #   (req, res, next) =>
  #     return res.sendStatus(403) if not req.user?

  #     #FIXME: dirty
  #     toSearch = {}
  #     toSearch[key] = req.user.id
  #     @resource.FetchBy toSearch, (err, instance) ->
  #       return res.status(403).send err if err?

  #       if
  #     return res.sendStatus(403) if not req.params[key]? or parseInt(req.params[key]) isnt req.user.id

  #     next()

  Nodulator.Route.prototype.Auth = (args...) ->
    Nodulator.Route.Auth args...

  Nodulator.Route.prototype.HasProperty = (args...) ->
    Nodulator.Route.HasProperty args...

  Nodulator.Route.prototype.IsOwn = (args...) ->
    Nodulator.Route.IsOwn args...


  #Used to wrap _Add call to allow global permissions restrictions on Route
  _AddBack = Nodulator.Route.prototype._Add
  Nodulator.Route.prototype._Add = (args...) ->
    if not @config?
      return _AddBack.apply @, args

    done = args.splice(args.length - 1, 1)[0]

    if @config.restrict? and typeof(@config.restrict) is 'function'
      args.push @config.restrict

    args.push done
    _AddBack.apply @, args

  {name: 'Account'}
