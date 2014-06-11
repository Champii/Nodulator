_ = require 'underscore'
express = require 'express'
http = require 'http'
bodyParser = require 'body-parser'

# Resource = require './Resource'
# Model = require './Model'

sql = require './connectors/sql'

class CoffeeHelper

  app: null
  server: null
  resources: {}
  routes: {}

  constructor: ->
    @app = express()

    @app.use bodyParser()

    @server = http.createServer @app

    @server.listen 3000

  Resource: (resourceName) ->
    if @resources[resourceName]?
      return @resources[resourceName]

    @resources[resourceName] = require('./Resource')()

    @resources[resourceName].SetHelpers resourceName, @app

    # for key, res of @resources
    #   console.log 'Table', key, res.table, res.resName

    @_DefaultRoutes @resources[resourceName], resourceName

    @resources[resourceName]

  _DefaultRoutes: (Resource, resName) ->
    @app.get '/api/1/' + resName, (req, res) ->

      Resource.List (err, results) ->
        return console.log err if err?

        res.send 200, _(results).invoke 'ToJSON'

    @app.get '/api/1/' + resName + '/:id', (req, res) ->

      Resource.Fetch req.params.id, (err, result) ->
        return console.log err if err?

        res.send 200, result.ToJSON()

    @app.post '/api/1/' + resName, (req, res) ->

      Resource.Deserialize req.body, (err, result) ->
        return console.log err if err?

        result.Save (err) ->
          return console.log err if err?

          res.send 200, result.ToJSON()

    @app.put '/api/1/' + resName + '/:id', (req, res) ->
      Resource.Fetch req.params.id, (err, result) ->
        return console.log err if err?

        _(result).extend req.body

        result.Save (err) ->
          return console.log err if err?

          res.send 200, result.ToJSON()

module.exports = new CoffeeHelper
