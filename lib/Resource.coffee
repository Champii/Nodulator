_ = require 'underscore'
async = require 'async'

Account = require './Account'

module.exports = (table, config, app, routes, name) ->
  table = table

  class Resource
    constructor: (blob) ->
      for key, value of blob
        @[key] = value

    @setRoutes : () ->
      Resource.routes.resource = @

    Save: (done) ->
      exists = @id?

      table.Save @Serialize(), (err, id) =>
        return done err if err?

        if !exists
          @id = id

        done null, @

    Delete: (done) ->
      table.Delete @id, done

    # Send to the database
    Serialize: ->
      res = {}
      for key, value of @ when typeof value isnt 'function' and value?
        content = @_content value
        if content?
          res[key] = content
      res

    _content: (value) ->
      ### FIXME : test linked objects
      if typeof value is 'object'
        if value instanceof Resource
          return value.Serialize()
        if value instanceof Array
          res = []
          for content of value
            @_content content
          return res
      else
      ###
      return value

    ToJSON: ->
      @Serialize()

    @Fetch: (id, done) ->
      table.Find id, (err, blob) =>
        return done err if err?

        @Deserialize blob, done

    @FetchBy: (field, id, done) ->
      fieldDict = {}
      fieldDict[field] = id
      table.FindWhere '*', fieldDict, (err, blob) =>
        return done err if err?

        @Deserialize blob, done

    # FIXME : test
    @FetchListBy: (field, id, done) ->
      res = []
      @FetchBy field, id, (err, blob) ->
        return done err if err?

        res.push blob
      res

    @List: (done) ->
      table.Select 'id', {}, {}, (err, ids) =>
        return done err if err?

        async.map _(ids).pluck('id'), (item, done) =>
          @Fetch item, done
        , done

    # Fetch from database
    @Deserialize: (blob, done) ->
      res = @

      done null, new res blob

    @_SetHelpers: (_table, _config, _app, _routes, _name) ->
      @table = table = _table
      @config = _config
      @app = _app
      @lname = _name.toLowerCase()

      if @config? and @config.account?
        @account = new Account _app, @lname, @, @config
      @routes = new _routes(@, _app, @config)
      @

  Resource._SetHelpers(table, config, app, routes, name)
