_ = require 'underscore'
async = require 'async'

Account = require './Account'

class Route

  constructor: (@app, resName, Resource, @config) ->
    @resName = resName + 's'

    # console.log @config

    if @config? and @config.account?
      @account = new Account @app, resName, Resource, @config

    @app.get '/api/1/' + @resName, (req, res) ->

      Resource.List (err, results) ->
        return console.log err if err?

        res.send 200, _(results).invoke 'ToJSON'

    @app.get '/api/1/' + @resName + '/:id', (req, res) ->

      Resource.Fetch req.params.id, (err, result) ->
        return console.log err if err?

        res.send 200, result.ToJSON()

    @app.post '/api/1/' + @resName, (req, res) ->

      Resource.Deserialize req.body, (err, result) ->
        return console.log err if err?

        result.Save (err) ->
          return console.log err if err?

          res.send 200, result.ToJSON()

    @app.put '/api/1/' + @resName + '/:id', (req, res) ->
      Resource.Fetch req.params.id, (err, result) ->
        return console.log err if err?

        _(result).extend req.body

        result.Save (err) ->
          return console.log err if err?

          res.send 200, result.ToJSON()

  Add: (type, url, done) ->
    @app[type] '/api/1/' + @resName + url, done


module.exports = Route
