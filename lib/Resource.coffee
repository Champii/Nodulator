_ = require 'underscore'
async = require 'async'

Db = require './Db'

class Resource

  @db = null
  @type = null
  @name = null

  constructor: (blob) ->
    for key, value of blob
      @[key] = value

  Save: (done) ->
    exists = @id?

    Resource.db.Save @Serialize(), (err, id) =>
      return done err if err?

      if !exists
        @id = id

      done null, @

  Serialize: ->
    res = {}
    for key, value of @ when typeof value isnt 'function'
      res[key] = value

    res

  ToJSON: ->
    @Serialize()

  @Fetch: (id, done) ->
    Resource.db.Fetch id, (err, blob) ->
      return done err if err?

      Resource.Deserialize blob, done

  @List: (done) ->
    @db.List (err, ids) =>
      return done err if err?

      async.map _(ids).pluck('id'), Resource.type.Fetch, done

  @Deserialize: (blob, done) ->
    done null, new @type blob

module.exports = Resource
