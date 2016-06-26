async = require 'async'
DB = require \./Connectors
Schema = require \../../Common/Schema
# N = null
module.exports = (config, routes, name) ->
  # if not N?
  #   N := require \../Nodulator
  class Resource extends require(\../../Common/Resource)(config, routes, name, N)

    Save: @_WrapPromise @_WrapResolvePromise (done) ->
      # console.log ''
      # serie = @Serialize()

    Delete: @_WrapPromise @_WrapResolvePromise (done) ->
      @_table.Delete @id, done

    @Create = @_WrapPromise @_WrapResolvePromise @_WrapWatchArgs (blob = {}, done) ->
      resource = @
      if typeof! blob is \Function
        done = blob
        blob = {}

      @_table.Insert blob, {}, done

    Set: @_WrapPromise @_WrapResolvePromise (blob, done) ->

      toChange = {}

      if is-type \Function blob
        blob @
        toChange = @
      else
        for k, v of blob
          # if k in map (.name), @_schema.properties
          if typeof! v is \Function
            toChange[k] = v!
          else
            toChange[k] = v

      # console.log 'BLOB' blob, toChange
      id = null
      if typeof! @id is \Function
        id = @id!
      else
        id = @id

      @_table.Update toChange, {id: id}, (err, data) ~>
        return done err if err?

        done null @


    @_Changed = -> @_watchers |> each (.dep._Changed!)
    Changed: -> @Res._Changed!

    ResolveFuncs: ->
      res = {}
      @_schema.properties |> each ~>
        return if not @[it.name]?
        if typeof! @[it.name] is \Function
          res[it.name] = @[it.name]!
        else
          res[it.name] = @[it.name]
      if typeof! @id is \Function
        res.id = @id!
      res

  Resource.DB = DB
  Resource._PrepareResource(config, routes, name)
  Resource
