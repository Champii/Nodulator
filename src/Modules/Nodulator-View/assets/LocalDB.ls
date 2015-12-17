_ = require 'underscore'

tables = {}

ChangeWatcher = require './ChangeWatcher.ls'

class LocalDB

  name: ''
  # insertSync: []
  # deleteSync: []

  (@resource) ->
    @fetched = []
    @collection = []
    @client = new N.Client @resource._type
    name = @resource._type[to -2]*''
    socket.on \new_ + name, ~>
      console.log 'New', it
      @collection.push it
      @resource._Changed!
    socket.on \update_ + name, (item) ~>
      console.log 'Update', item
      # return if item.id not in (@collection |> map (.id))
      idx = @collection |> find-index -> it.id is item.id
      # console.log idx, @collection.idx
      @collection[idx] = item
      console.log 'COLLECTION' @collection, @resource.watchers
      # @resource._Changed!
      N.bus.emit \update_ + name + \_ + item.id, item
    socket.on \delete_ + name, (item) ~>
      # return if it.id not in @collection |> map (.id)
      @collection = _(@collection).reject (record) -> record.id is item.id
      @resource._Changed!

  Select: (where, options, done) ->
    res = map (-> {} import it), _(@collection).where(where)

    if options?.limit?
      offset = options.offset || 0
      res = res[offset til options.limit]

    if options?.limit is 1
      if not (@collection |> find -> it.id === options.id)
        return @client.Fetch where, (err, data) ~>
          return done err if err?

          @collection.push data
          @resource._Changed!
          done null data

    else
      # console.log 'BEFORE' not (@fetched |> find -> console.log it; it === where)
      if not (@fetched |> find -> it === where)
        @fetched.push where
        return @client.List where, (err, data) ~>
          return done err if err?

          if data !== res
            data
              |> each (item) ~>
                | item.id in map (.id), @collection => @collection[@collection |> find-index -> it.id is item.id] <<< item
                | _                                 => @collection.push item

            @resource._Changed!
          done null data

    done null, res

  Insert: (fields, done) ->
    @client.Create fields, (err, data) ~>
      return done err if err?

      @collection.push elem
      # @resource._Changed!
      done null, data

  Update: (fields, where, done) ->
    @client.Set where.id, fields, (err, data) ~>
      return done err if err?
      idx = @collection |> find-index -> it.id is where.id
      @collection[idx] = data
      # @resource._Changed!

    done null fields
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

N.LocalDB = LocalDB
