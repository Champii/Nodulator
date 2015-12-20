async = require \async

drivers = do
  ClientDB: require \./ClientDB

class DB

  tableName: null

  (@tableName, resource) ->
    @drivers = {}
    @driver = new drivers.ClientDB resource

  Find: (id, done) ->
    @FindWhere '*', {id: +id}, done

  FindWhere: (fields, where, done) ->
    @Select fields, where, {limit: 1}, (err, results) ~>
      return done err if err?

      if results.length is 0
        return done do
          status: 'not_found'
          reason: JSON.stringify where
          source: @tableName

      done null, results[0]

  Select: (fields, where, options, done) ->
    @driver.Select where, options, done

  Save: (blob, config, done) ->
    if blob.id?
      @Update blob, {id: blob.id}, done
    else
      @Insert blob, config, done

  Insert: (blob, config, done) ->
    # driver = @drivers[config.db.type]
    @driver.Insert blob, done


  Update: (blob, where, done) ->
    @driver.Update blob, where, done

  Delete: (id, done) ->
    @driver.Delete {id: id}, (err, affected) ->
      return done err if err?
      return done {error: 'Error on Delete'} if !affected

      done null, affected

  AddDriver: (config) ->
    return if @drivers[config.db.type?]?

    # drivers[config.db.type].AddTable @tableName
    # @drivers[config.db.type] = new drivers[config.db.type] @tableName

  @Reset = ->
    values drivers |> each (._Reset?!)
    internalDriver.Reset! if internalDriver?

module.exports = DB

module.exports._reset = ->
  # driver._Reset() if driver?
N = require '../../Nodulator'
