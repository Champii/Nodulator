_ = require 'underscore'
fs = require 'fs'
path = require 'path'
http = require 'http'
express = require 'express'
bodyParser = require 'body-parser'
expressSession = require 'express-session'
# RedisStore = require('connect-redis')(expressSession)

#FIXME: Hack to prevent EADDRINUSE from mocha
port = 3000

class Nodulator

  app: null
  express: null
  server: null
  resources: {}
  directives: {}
  routes: {}
  config: null
  table: null
  authApp: false
  defaultConfig:
    dbType: 'SqlMem'

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

    @server = http.createServer @app

    # @sessionStore = new RedisStore
    #  host: 'localhost'

    @app.use expressSession
      key: 'Nodulator'
      secret: 'Nodulator'
      # store: @sessionStore
      resave: true
      saveUninitialized: true


    @db = require('./connectors/sql')

  Resource: (name, routes, config, _parent) ->

    name = name.toLowerCase()
    if @resources[name]?
      return @resources[name]

    if routes? and not routes.prototype
      config = routes
      routes = null

    @Config() if !(@config?) # config of Nodulator instance

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

  Config: (config) ->
    if @config?
      return

    @config = config
    @config = @defaultConfig if !(config?)

    for k, v of @defaultConfig
      @config[k] = v if not @config[k]?

    @table = @db(@config).table

    @server.listen @config.port || port++

  Use: (module) ->
    module @

  ExtendDefaultConfig: (config) ->
    @defaultConfig = _(@defaultConfig).extend config

  Bus: require './Bus'
  bus: new @::Bus()

  Route: require './Route'

  Reset: (done) ->
    if not @server?
      @Init()
      done() if done?
      return

    @resources = {}
    @config = null
    @table = null

    @db._reset() if @db?
    @Init()

    done() if done?

  _ListEndpoints: (done) ->
    endpoints = []
    for endpoint in @app._router.stack
      if endpoint.route?
        res = {}
        res[endpoint.route.path] = key for key of endpoint.route.methods
        endpoints.push res
    done(endpoints) if done?

module.exports = new Nodulator
