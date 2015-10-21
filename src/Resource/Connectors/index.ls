async = require \async
global import require \prelude-ls
N = require '../../..'

drivers = do
  Mongo: require \./Mongo
  Mysql: require \./Mysql
  SqlMem: require \./SqlMem


class InternalDriver

  -> @Init!

  Init: ->

    @driver = drivers[N.config.db.type] N.config.db

    # Ensure that the database exists
    if N.config.db.type is \Mongo
      @driver.Insert 'internal_ids', {id: 'a', test: true}, (err, res) ~>
        return console.error err if err?

        @driver.Delete 'internal_ids', {id: 'a'}, (err, res) ~>
          return console.error err if err?
    if N.config.db.type is \SqlMem
      drivers[N.config.db.type].AddTable 'internal_ids'

  CreateIdEntry: (name, done) ->
    @driver.Select 'internal_ids', \*, {}, {}, (err, nextIds) ~>
      if err? or not find (.name is name), nextIds
        @driver._NextId 'internal_ids', (err, entryId) ~>
          @driver._NextId name, (err, nextId) ~>
            @driver.Insert 'internal_ids', {name: name, nextId: nextId, id: entryId}, (err, res) ~>

              @driver.Select 'internal_ids', \*, {name: name}, {}, (err, res) ~>
                @driver.Update 'internal_ids', res.0, {}, (err, res) ->
                  done! if done?
      else
        done! if done?

  NextId: (name, done) ->
    @driver.Select 'internal_ids', \*, {name: name}, {}, (err, fields) ~>
      return done err if err?

      if not fields.length
        @CreateIdEntry name, ~> @NextId name, done
      else
        fields.0.nextId++
        @driver.Update 'internal_ids', {id: fields.0.id, nextId: fields.0.nextId, name: name}, {}, (err, res) ->
          return done err if err?

          done null, fields?.0?.nextId - 1


  Reset: ->
    @driver.Drop 'internal_ids'
    @Init!


internalDriver = null

class DB

  tableName: null

  (@tableName) ->
    internalDriver := new InternalDriver if not internalDriver?
    @drivers = {}

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

  @_WrapDrivers = (cb) ->
    (...args) ->
      done = args.pop!
      async.mapSeries values(@drivers), (it, done) ~>
        cb.apply @, [it, ...args, done]
      , (err, results) ->
        return done err if err?

        done null, flatten results

  Select: @_WrapDrivers (driver, fields, where, options, done) ->
    driver.Select @tableName, fields, where, options, done

  Save: (blob, config, done) ->
    if blob.id?
      @Update blob, {id: blob.id}, done
    else
      @Insert blob, config, done

  Insert: (blob, config, done) ->
    driver = @drivers[config.db.type]
    internalDriver.NextId @tableName, (err, nextId) ~>
      return done err if err?

      blob.id = nextId
      driver.Insert @tableName, blob, done


  Update: @_WrapDrivers (driver, blob, where, done) ->
    driver.Update @tableName, blob, where, done

  Delete: @_WrapDrivers (driver, id, done) ->
    driver.Delete @tableName, {id: id}, (err, affected) ->
      return done err if err?
      return done {error: 'Error on Delete'} if !affected

      done null, affected

  AddDriver: (config) ->
    return if @drivers[config.type?]?

    drivers[config.type].AddTable @tableName
    @drivers[config.type] = drivers[config.type](config)

  @Reset = ->
    values drivers |> each (._Reset?!)
    internalDriver.Reset! if internalDriver?

module.exports = DB

module.exports._reset = ->
  # driver._Reset() if driver?
