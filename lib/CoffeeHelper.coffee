_ = require 'underscore'
express = require 'express'
http = require 'http'
bodyParser = require 'body-parser'

Resource = require './Resource'

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

    @resources[resourceName] = Resource

    @resources[resourceName].table = sql.table resourceName
    @resources[resourceName].resName = resourceName

    @_DefaultRoutes @resources[resourceName]

    @resources[resourceName]

  _DefaultRoutes: (Resource) ->
    @app.get '/api/1/' + Resource.resName, (req, res) ->

      Resource.List (err, results) ->
        return console.log err if err?

        res.send 200, _(results).invoke 'ToJSON'

    @app.get '/api/1/' + Resource.resName + '/:id', (req, res) ->

      Resource.Fetch req.params.id, (err, result) ->
        return console.log err if err?

        res.send 200, result.ToJSON()

    @app.post '/api/1/' + Resource.resName, (req, res) ->

      Resource.Deserialize req.body, (err, result) ->
        return console.log err if err?

        result.Save (err) ->
          return console.log err if err?

          res.send 200, result.ToJSON()

    @app.put '/api/1/' + Resource.resName + '/:id', (req, res) ->

      Resource.Fetch req.params.id, (err, result) ->
        return console.log err if err?

        _(result).extend req.body

        result.Save (err) ->
          return console.log err if err?

          res.send 200, result.ToJSON()

module.exports = new CoffeeHelper
