_ = require 'underscore'

tables = {}

ChangeWatcher = require './ChangeWatcher.ls'

class LocalDB

  name: ''
  collection: []
  insertSync: []
  deleteSync: []
  fetched: []

  (@resource) ->
    @client = new N.Client @resource._type
    socket.on \new_ + @resource._type[to -2]*'', ~>
      @collection.push it
      @resource.watcher?.dep._Changed!
    socket.on \update_ + @resource._type[to -2]*'', ~>
      return if it.id not in @collection |> map (.id)
      @Update it, id: it.id
      @resource.watcher?.dep._Changed!
    socket.on \delete_ + @resource._type[to -2]*'', ~>
      return if it.id not in @collection |> map (.id)
      @Delete id: it.id
      @resource.watcher?.dep._Changed!

  Select: (where, options, done) ->
    res = map (-> {} import it), _(@collection).where(where)

    if options?.limit?
      offset = options.offset || 0
      res = res[offset til options.limit]

    if option?.limit is 1
      if not (@fetched |> find -> it === where)
        @client.Fetch where, (err, data) ~>
          return console.error err if err?

          if data !== res
            @fetched.push where
            @collection.push res
    else
      if not (@fetched |> find -> it === where)
        return @client.List where, (err, data) ~>
          return console.error err if err?

          if data !== res
            @fetched.push where
            @collection = @collection.concat data
            done null, data

    done null, res

  Insert: (fields, done) ->
    @insertSync.push {} import fields
    @client.Create fields, (err, data) ~>
      elem = _ @insertSync .findWhere fields
      @insertSync = _(@insertSync).reject (item) -> item !== elem
      if err?
        return

      @collection.push elem

    done null, fields

  Update: (fields, where, done) ->
    save = _(@collection).findWhere(where)
    updated = _(@collection).findWhere(where) import fields

    @client.Set where.id, fields, (err, data) ~>
      if err?
        idx = @collection |> find-index -> it.id is where.id
        @collection.idx = save
        # ChangeWatcher.Invalidate!
        return

    done null updated

  Delete: (where, done) ->
    idx = @collection |> find-index -> it.id is where.id
    save = @collection[idx]
    @collection = _(@collection).reject (item) -> item.id is where.id

    @client.Delete where, (err, data) ~>
      if err?
        @collection.splice idx, 0, save
        # ChangeWatcher.Invalidate!

    done null, 1

N.LocalDB = LocalDB
