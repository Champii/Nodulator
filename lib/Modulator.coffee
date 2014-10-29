_ = require 'underscore'
express = require 'express'
http = require 'http'
bodyParser = require 'body-parser'

class Modulator

  app: null
  express: null
  server: null
  resources: {}
  routes: {}
  config: null
  table: null
 
  constructor: ->
    @express = express

    @app = express()

    @app.use bodyParser.urlencoded
      extended: true

    @app.use bodyParser.json
      extended: true

    @server = http.createServer @app

    @server.listen 3000

    @db = require('./connectors/sql')

  Resource: (name, routes, config) ->
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
    
    @resources[name] = resource =
      require('./resource')(@table(name + 's'), config, @app, routes, name)

    resource

  Config: (@config) ->
    @config = @_DefaultConfig() if !(@config?)

    @table = @db(@config).table

  _DefaultConfig: ->
    dbType: 'SqlMem'

  Route: require('./route')

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

module.exports = new Modulator
