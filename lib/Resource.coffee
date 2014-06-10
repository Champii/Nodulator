_ = require 'underscore'
async = require 'async'

table = require './connectors/sql'

class Resource

  @table = null
  @resName = null

  constructor: (blob) ->
    for key, value of blob
      @[key] = value

  Save: (done) ->
    exists = @id?

    Resource.table.Save @Serialize(), (err, id) =>
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
    Resource.table.Find id, (err, blob) ->
      return done err if err?

      Resource.Deserialize blob, done

  @List: (done) ->
    Resource.table.Select 'id', {}, {}, (err, ids) =>
      return done err if err?

      async.map _(ids).pluck('id'), Resource.Fetch, done

  @Deserialize: (blob, done) ->
    done null, new Resource blob

module.exports = Resource
