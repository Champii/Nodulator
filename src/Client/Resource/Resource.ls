async = require 'async'
ClientDB = require \./Connectors/ClientDB
Schema = require \../../Common/Schema
# N = null
module.exports = (config, routes, name) ->
  # if not N?
  #   N := require \../Nodulator

  class Resource extends require(\../../Common/Resource)(config, routes, name, N)
    @N = N
    @_type = name

    (blob) ->

      @_type = name

      if blob.promise?
        @_promise = blob.promise
        return @

      for k, v of blob
        if typeof! v is \Array
          blob[k] = map (-> new N.resources[k.toLowerCase()] it), v

      if not (db.collection |> find ~> it.id is blob.id)
        db.collection.push blob

      import blob
      @

    Add: ->
    Save: @_WrapPromise @_WrapResolvePromise (done) ->
      # serie = @Serialize()

    Delete: @_WrapPromise @_WrapResolvePromise (done) ->
      db.Delete {id: @id}, done

    @Create = @_WrapPromise @_WrapResolvePromise @_WrapWatchArgs (blob = {}, done) ->
      resource = @
      if typeof! blob is \Function
        done = blob
        blob = {}

      db.Insert blob, done

    @List = @_WrapPromise @_WrapResolvePromise @_WrapWatchArgs (blob = {}, done) ->
      resource = @
      if typeof! blob is \Function
        done = blob
        blob = {}

      db.Select blob, {}, (err, data) ->
        return done err if err?

        async.mapSeries data, (item, done) ->
          done null new resource item
        , done

    @Fetch = @_WrapPromise @_WrapResolvePromise @_WrapWatchArgs (blob = {}, done) ->
      resource = @
      if typeof! blob is \Function
        done = blob
        blob = {}

      if typeof! blob is \Number
        blob = id: blob

      db.Select blob, {limit: 1}, (err, data) ->
        return done err if err?

        done null new resource data

    Set: @_WrapPromise @_WrapResolvePromise (blob, done) ->
      @ <<< blob
      db.Update blob, {id: @id}, (err, data) ->
        return done err if err?

        done err, data

    @_PrepareResource = (_config, _routes, _name, _parent = null) ->
      @debug-res.Log 'Preparing resource'

      console.log arguments
      @lname = _name.toLowerCase()

      # @_table = new DB @lname + \s
      # if not _config?.abstract
      #   @_table.AddDriver _config
      # else if not _config? or (_config? and not _config.abstract)
      #   @_table.AddDriver @config

      @config = _config
      @INITED = false

      @_schema = new Schema @lname, _config?.schema
      @_parent = _parent
      if @_parent?
        @_schema <<< @_parent._schema.Inherit!

      @_schema.Resource = @

      @Route = _routes
      @_routes = _routes

      @

    # @Init = ->


    @_Changed = -> console.log 'Watchers', @watchers; @watchers |> each (.dep._Changed!)

  Resource.db = db = new ClientDB Resource
  Resource._PrepareResource(config, routes, name)
  Resource
