_ = require 'underscore'
async = require 'async'

Route = require './Route'

module.exports = ->

  table = null
  resName = null
  route = null
  config = null

  class Resource

    constructor: (blob) ->
      for key, value of blob
        @[key] = value

    Save: (done) ->
      exists = @id?

      table.Save @Serialize(), (err, id) =>
        return done err if err?

        if !exists
          @id = id

        done null, @

    Serialize: ->
      res = {}
      for key, value of @ when typeof value isnt 'function' and typeof value isnt 'object' and value?
        res[key] = value
      res

    ToJSON: ->
      @Serialize()

    @Route: (type, url, done) ->
      route.Add type, url, done

    @Fetch: (id, done) ->
      table.Find id, (err, blob) =>
        return done err if err?

        @Deserialize blob, done

    @List: (done) ->
      table.Select 'id', {}, {}, (err, ids) =>
        return done err if err?

        async.map _(ids).pluck('id'), (item, done) =>
          @Fetch item, done
        , done

    @Deserialize: (blob, done) ->
      done null, new @ blob

    @_SetHelpers: (_table, _resName, _app, _config) ->
      @table = table = _table
      @resName = resName = _resName
      @route = route = new Route _app, _resName, @, _config
      @config = config = _config
