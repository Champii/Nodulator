_ = require 'underscore'
async = require 'async'
passport = require 'passport'
expressSession = require 'express-session'
cookieParser = require 'cookie-parser'

LocalStrategy = require('passport-local').Strategy

class Account

  constructor: (@app, @resName, Resource, @config) ->

    @userField =
      usernameField: 'username'
      passwordField: 'password'

    if @config.account.fields?
      @userField = @config.account.fields

    @ExtendResource Resource

    @InitPassport Resource

    @InitRoutes resName

  InitPassport: (Resource) ->

    # @app.use expressSession
    #   secret: 'Modulator secret'
    #   saveUninitialized: true
    #   resave: true

    @app.use passport.session()

    passport.serializeUser (user, done) ->
      done null, user.id

    passport.deserializeUser (id, done) ->
      Resource.Fetch id, done

    passport.use new LocalStrategy @userField, (username, password, done) =>
      Resource[@methodName] username, (err, user) =>
        return done err if err? and err.status isnt 'not_found'
        return done null, false, {message: 'Incorrect Username/password'} if err? or !(user?) or user[@userField.passwordField] isnt password
        return done null, user

  InitRoutes: (resName) ->
    @app.post '/api/1/' + resName + 's' + '/login', passport.authenticate('local'), (req, res) =>
      if @config.account? and @config.account.loginCallback?
        @config.account.loginCallback req.user, ->
          res.status(200).send()
      else
        res.status(200).send()

    @app.post '/api/1/' + resName + 's' + '/logout', (req, res) =>
      if @config.account? and @config.account.logoutCallback?
        @config.account.logoutCallback req.user, ->
          req.logout()
          res.status(200).send()
      else
        req.logout()
        res.status(200).send()

  ExtendResource: (Resource) ->
    @methodName = 'FetchBy' + @userField.usernameField[0].toUpperCase() + @userField.usernameField[1..].toLowerCase()
    userField = @userField

    Resource[@methodName] = (login, done) ->
      fields = {}
      fields[userField.usernameField] = login

      @table.FindWhere "*", fields, (err, blob) =>
        return done err if err?

        @Deserialize blob, done

module.exports = Account
