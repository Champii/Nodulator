_ = require 'underscore'
async = require 'async'
passport = require 'passport'
expressSession = require 'express-session'
cookieParser = require 'cookie-parser'

LocalStrategy = require('passport-local').Strategy

class Account

  constructor: (@app, resName, Resource, @config) ->

    @userField =
      usernameField: 'username'
      passwordField: 'password'

    if @config.account.fields?
      @userField = @config.account.fields

    @ExtendResource Resource

    @InitPassport Resource

    @InitRoutes()

  InitPassport: (Resource) ->

    @app.use cookieParser()
    @app.use expressSession secret: 'Modulator secret'
    @app.use passport.initialize()
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

  InitRoutes: ->
    @app.post '/api/1/login', passport.authenticate('local'), (req, res) ->
      res.send 200

    @app.post '/api/1/logout', (req, res) ->
      req.logout()
      res.send 200

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