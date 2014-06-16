_ = require 'underscore'
express = require 'express'
http = require 'http'
bodyParser = require 'body-parser'

class Modulator

  app: null
  server: null
  resources: {}
  config: {}
  table: null

  constructor: ->
    @app = express()

    @app.use bodyParser()

    @server = http.createServer @app

    @server.listen 3000

  Resource: (resourceName, config) ->
    if @resources[resourceName]?
      return @resources[resourceName]

    @resources[resourceName] = require('./Resource')()

    resource = @resources[resourceName]

    @config = @_DefaultConfig() if @config is {}

    resource._SetHelpers @table(resourceName), resourceName, @app, config

    resource

  Config: (@config) ->
    @table = require('./connectors/sql')(@config).table

  _DefaultConfig: ->
    dbType: 'SqlMem'

module.exports = new Modulator
