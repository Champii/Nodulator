_ = require 'underscore'
async = require 'async'

Modulator = require '../'
Account = require './Account'

module.exports = (table, config, app, routes, name) ->

  class Resource

    constructor: (blob) ->
      @table = @.__proto__.constructor.table
      for key, value of blob
        @[key] = value

    Save: (done) ->
      exists = @id?

      @table.Save @Serialize(), (err, id) =>
        return done err if err?

        if !exists
          @id = id

        done null, @

    Delete: (done) ->
      @table.Delete @id, done

    # Send to the database
    Serialize: ->
      res = {}
      for key, value of @ when typeof value isnt 'function' and value? and key isnt 'table'
        content = @_content value
        if content?
          res[key] = content
      res

    _content: (value) ->
      # FIXME : test linked objects
      if typeof value is 'object' and value.Serialize?
        value.Serialize()
      # else if typeof value is 'object'
      #   JSON.stringify value
      else
        value

    ToJSON: ->
      @Serialize()

    @Fetch: (id, done) ->
      @table.Find id, (err, blob) =>
        return done err if err?

        @resource.Deserialize blob, done

    @FetchBy: (field, value, done) ->
      fieldDict = {}
      fieldDict[field] = value
      @table.FindWhere '*', fieldDict, (err, blob) =>
        return done err if err?

        @resource.Deserialize blob, done

    # FIXME : test
    @ListBy: (field, id, done) ->
      res = []
      @resource.FetchBy field, id, (err, blob) ->
        return done err if err?

        res.push blob
      res

    @List: (done) ->
      @table.Select 'id', {}, {}, (err, ids) =>
        return done err if err?

        async.map _(ids).pluck('id'), (item, done) =>
          @resource.Fetch item, done
        , done

    # Fetch from database
    @Deserialize: (blob, done) ->
      res = @resource

      done null, new res blob

    @_PrepareResource: (_table, _config, _app, _routes, _name) ->
      @table = _table
      @config = _config
      @app = _app
      @lname = _name.toLowerCase()
      @resource = @
      @_routes = _routes

      @

    @Init: ->
      @resource = @
      Modulator.resources[@lname] = @

      if @config? and @config.account?
        @account = new Account @app, @lname, @, @config

      if @config? and @config.abstract
        @Extend = (name, routes, config) =>
          Modulator.Resource name, routes, config, @
      else if @_routes?
        @routes = new @_routes(@, @app, @config)

  Resource._PrepareResource(table, config, app, routes, name)
