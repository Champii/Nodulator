_ = require 'underscore'
express = require 'express'
http = require 'http'
bodyParser = require 'body-parser'

class Modulator

  app: null
  server: null
  resources: {}
  config: null
  table: null

  constructor: ->
    @app = express()

    @app.use bodyParser()

    @server = http.createServer @app

    @server.listen 3000

    @db = require('./connectors/sql')

  Resource: (resourceName, config) ->
    if @resources[resourceName]?
      return @resources[resourceName]

    @resources[resourceName] = require('./Resource')()

    resource = @resources[resourceName]

    @Config() if !(@config?)

    resource._SetHelpers @table(resourceName + 's'), resourceName, @app, config

    resource

  Config: (@config) ->
    @config = @_DefaultConfig() if !(@config?)

    @table = @db(@config).table

  _DefaultConfig: ->
    dbType: 'SqlMem'

  Reset: (done) ->
    @server.close()
    @resources = {}
    @config = null
    @table = null

    @app = express()

    @app.use bodyParser()

    @server = http.createServer @app

    @server.listen 3000

    @db._reset()
    @db = require('./connectors/sql')

    done() if done?

module.exports = new Modulator
