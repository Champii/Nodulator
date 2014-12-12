_ = require 'underscore'
fs = require 'fs'
path = require 'path'
http = require 'http'
jade = require 'jade'
express = require 'express'
passport = require 'passport'
bodyParser = require 'body-parser'
expressSession = require 'express-session'
RedisStore = require('connect-redis')(expressSession)

Assets = require './Assets'
Socket = require './Socket'

class Modulator

  app: null
  express: null
  server: null
  resources: {}
  directives: {}
  routes: {}
  config: null
  table: null
  assets: {}

  constructor: ->

    @Init()

  Init: ->

    @appRoot = path.resolve '.'

    @express = express

    @app = @express()

    @app.use bodyParser.urlencoded
      extended: true

    @app.use bodyParser.json
      extended: true

    @assets = new Assets @app, @appRoot, 'client/views'

    @server = http.createServer @app

    @sessionStore = new RedisStore
     host: 'localhost'

    @app.use expressSession
      key: 'modulator'
      secret: 'modulator'
      store: @sessionStore
      resave: true
      saveUninitialized: true

    @app.use passport.initialize()

    @server.listen 3000
    @socket = new Socket @server, @sessionStore, passport

    @db = require('./connectors/sql')

  Resource: (name, routes, config, _parent) ->

    name = name.toLowerCase()
    if name is 'user'
      throw new Error 'Resource name \'user\' is reserved'

    if @resources[name]?
      return @resources[name]

    if routes? and not routes.prototype
      config = routes
      routes = null

    @Config() if !(@config?) # config of Modulator instance

    if not routes? or routes.prototype not instanceof @Route
      routes = @Route

    if _parent?
      @resources[name] = resource = _parent
      @resources[name]._PrepareResource @table(name + 's'), config, @app, routes, name
    else
      table = null
      if not config? or (config? and not config.abstract)
        table = @table(name + 's')

      @resources[name] = resource =
        require('./Resource')(table, config, @app, routes, name)

    resource

  Config: (@config) ->
    @config = @_DefaultConfig() if !(@config?)

    @table = @db(@config).table

  _DefaultConfig: ->
    dbType: 'SqlMem'

  Route: require('./Route')

  Reset: (done) ->
    @server.close()
    @resources = {}
    @config = null
    @table = null

    @app = express()

    @app.use bodyParser.urlencoded
      extended: true

    @app.use bodyParser.json
      extended: true

    @server = http.createServer @app

    @server.listen 3000

    @db._reset()
    @db = require('./connectors/sql')

    done() if done?

  ListEndpoints: (done) ->
    endpoints = []
    for endpoint in @app._router.stack
      if endpoint.route?
        res = {}
        res[endpoint.route.path] = key for key of endpoint.route.methods
        endpoints.push res
    done(endpoints) if done?

  Run: ->
    # FIXME: ugly fix for favicon
    @app.get '/favicon.ico', (req, res) ->
      res.status(200).end()

    @app.get '*', (req, res) ->

      res.render 'index',
        user: {id: req.userId}

module.exports = new Modulator
