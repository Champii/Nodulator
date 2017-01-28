_ = require 'underscore'
async = require 'async'
cookieParser = require 'cookie-parser'
passport = require 'passport'

LocalStrategy = require('passport-local').Strategy

AccountResource = require \./AccountResource
NModule = require \../NModule

class NAccount extends NModule

  name: \NAccount

  defaultConfig:
    usernameField: 'username'
    passwordField: 'password'

  Init: ->
    N.authApp = true
    N.passport = passport

    # Init
    do ->

      if N.consoleMode
        return

      if not N.app?
        N.Route._InitServer()

      N.app.use N.passport.initialize()
      N.app.use N.passport.session()

#  AccountResource.Init()

    if N.assets?
      N.ExtendBeforeRender AccountResource._InjectUser

      N.ExtendAfterRender (req, res) ~>
        rend = 'auth-index'
        if req.user?
          rend = 'index'

        res.render rend

        # Returning false breaks the render loop
        return false

    N.AccountResource = (...args) ->
      if @resources[args[0]]?
        return @resources[args[0]]

      Account = AccountResource.Extend ...args

      if Account.config? and Account.config.fields?
        Account.userField = Account.config.fields

      Account._InitPassport()
      Account._InitLoginRoutes args[0]

      Account

    N.AccountResource._AccountResource = AccountResource

    N.Route.Auth = ->
      (req, res, next) ->
        return res.sendStatus(403) if not req.user?

        next()

    N.Route.HasProperty = (obj) ->
      (req, res, next) ~>
        return res.sendStatus(403) if not req.user?

        for key, item of obj
          if not req.user[key]? or req.user[key] isnt item
            return res.sendStatus(403)

        next()

    N.Route.IsOwn = (key) ->
      (req, res, next) ~>
        return next() if not req.params[key]?
        return res.sendStatus(403) if not req.user?
        return res.sendStatus(403) if parseInt(req.params[key]) isnt req.user.id

        next()

    N.Route.IsOwnDeep = (predicat) ->
      (req, res, next) ~>
        return res.sendStatus(403) if not req.user?
        return res.sendStatus(403) if predicat(req) isnt req.user.id

        next()

    # N.Route.IsOwnObject = (key) ->
    #   (req, res, next) ~>
    #     return res.sendStatus(403) if not req.user?

    #     #FIXME: dirty
    #     toSearch = {}
    #     toSearch[key] = req.user.id
    #     @resource.FetchBy toSearch, (err, instance) ->
    #       return res.status(403).send err if err?

    #       if
    #     return res.sendStatus(403) if not req.params[key]? or parseInt(req.params[key]) isnt req.user.id

    #     next()

    N.Route.prototype.Auth = (...args) ->
      N.Route.Auth ...args

    N.Route.prototype.HasProperty = (...args) ->
      N.Route.HasProperty ...args

    N.Route.prototype.IsOwn = (...args) ->
      N.Route.IsOwn ...args

    N.Route.prototype.IsOwnDeep = (...args) ->
      N.Route.IsOwnDeep ...args


    #Used to wrap _Add call to allow global permissions restrictions on Route
    _AddBack = N.Route.prototype._Add
    N.Route.prototype._Add = (...args) ->
      if not @config?
        return _AddBack.apply @, args

      done = args.splice(args.length - 1, 1)[0]

      if @config.restrict? and typeof(@config.restrict) is 'function'
        args.push @config.restrict

      args.push done
      _AddBack.apply @, args

module.exports = NAccount
