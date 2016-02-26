_ = require 'underscore'
# N = require '../../Nodulator'
tables = {}

rest = require 'rest'
mime = require('rest/interceptor/mime');

Client = rest.wrap(mime)

class RESTClient

  (@name) ->

  Fetch: (blob, done) ->
    Client method: \POST path: \/api/1/ + @name + '/fetch', headers: {'Content-Type': 'application/json'}, entity: blob
      .then ~> done null it.entity
      .catch done

  Create: (blob, done) ->
    Client method: \POST path: \/api/1/ + @name + '/create', headers: {'Content-Type': 'application/json'}, entity: blob
      .then ~> done null it.entity
      .catch done
  List: (blob, done) ->
    Client method: \POST path: \/api/1/ + @name + '/list', headers: {'Content-Type': 'application/json'}, entity: blob
      .then ~> done null it.entity
      .catch done
  Delete: (id, blob, done) ->
    Client method: \POST path: \/api/1/ + @name + '/delete/' + id, headers: {'Content-Type': 'application/json'}, entity: blob
      .then ~> done null it.entity
      .catch done

  Set: (id, blob, done) ->
    Client method: \POST path: \/api/1/ + @name + '/set/' + id, headers: {'Content-Type': 'application/json'}, entity: blob
      .then ~> done null it.entity
      .catch done

# @N.Client = RESTClient

dbs = {}

class ClientDB

  name: ''
  # insertSync: []
  # deleteSync: []

  (@resource) ->
    dbs[@resource._type] = @
    @fetched = []
    @collection = []
    @client = new RESTClient @resource._type
    @SetSockets!

  SetSockets: ->
    socket.on \new_ + @resource._type, @~OnNew
    socket.on \update_ + @resource._type, @~OnUpdate
    socket.on \delete_ + @resource._type, @~OnDelete

  OnNew: ->
    it = @ExtractAssocs it
    # console.log 'New', it
    @collection.push it
    @resource._Changed!
    @resource.N.bus.emit \new_ + @resource._type, it

  OnUpdate: (item) ->
    console.log 'Update' item
    item = @ExtractAssocs item
    # console.log 'Update', item
    # return if item.id not in (@collection |> map (.id))
    idx = @collection |> find-index -> it.id is item.id
    # console.log idx, @collection.idx
    if idx?
      # console.log 'Id ?', idx, item, @collection[idx]
      console.log 'Change' @collection[idx], item
      diff = @GetChange @collection[idx], item
      # console.log 'diff ?', diff
      @collection[idx] = item
    # @resource._Changed!0
      console.log 'diff' diff
      if keys diff .length
        @resource.N.bus.emit \update_ + @resource._type + \_ + item.id, diff
    else
      @OnNew item

  OnDelete: (item) ->
    item = @ExtractAssocs item
    # return if it.id not in @collection |> map (.id)
    @collection = _(@collection).reject (record) -> record.id is item.id
    @resource._Changed!

  ExtractAssocs: (blob) ->
    @resource._schema.assocs |> map ~>
      if blob[it.name]?
        dbs[it.type._type].ImportAssocs blob[it.name]
        delete blob[it.name]
    blob

  ImportAssocs: ->
    map @~OnUpdate, it

  GetChange: (base, toCmp)->
    res = {}
    for k, v of base when toCmp[k] !== v and typeof! v isnt \Object and typeof! v isnt \Array
      res[k] = toCmp[k]
    res

  Select: (where, options, done) ->
    res = map (-> {} import it), _(@collection).where(where)

    if options?.limit?
      offset = options.offset || 0
      res = res[offset til options.limit]

    if options?.limit is 1
      if not res.length
        return @client.Fetch where, (err, data) ~>
          return done err if err?

          data = @ExtractAssocs data
          @collection.push data
          # @resource._Changed!
          done null [data]

    else
      # console.log 'BEFORE' not (@fetched |> find -> console.log it; it === where)
      if not (@fetched |> find -> it === where)
        @fetched.push where
        return @client.List where, (err, data) ~>
          return done err if err?

          data = map @~ExtractAssocs, data
          if data !== res
            data
              |> each (item) ~>
                | item.id in map (.id), @collection => @collection[@collection |> find-index -> it.id is item.id] <<< item
                | _                                 => @collection.push item

            # @resource._Changed!
          done null data

    done null, res

  Insert: (fields, done) ->
    @client.Create fields, (err, data) ~>
      return done err if err?

      # @collection.push data
      # @resource._Changed!
      done null, data

  Update: (fields, where, done) ->
    @client.Set where.id, fields, (err, data) ~>
      return done err if err?
      idx = @collection |> find-index -> it.id is where.id
      # @collection[idx] <<< data
      # @resource._Changed!

      done null data
      # done null data

  Delete: (where, done) ->
    # idx = @collection |> find-index -> it.id is where.id
    # save = @collection[idx]
    @collection = _(@collection).reject (item) -> item.id is where.id

    @client.Delete where.id, where, (err, data) ~>
      return done err if err?
      # if err?
      #   @collection.splice idx, 0, save
        # ChangeWatcher.Invalidate!
      @resource._Changed!


    done null, 1

module.exports = ClientDB

module.exports.AddTable = (name) ->
  # if !(tables[name]?)
  #   tables[name] = []
  # tables[name]
