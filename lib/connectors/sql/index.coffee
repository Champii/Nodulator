driver = null

class Table

  name: null

  constructor: (@name) ->

  Find: (id, done) ->
    @FindWhere '*', {id: id}, done

  FindWhere: (fields, where, done) ->
    @Select fields, where, {limit: 1}, (err, results) ->
      return done err if err?

      if results.length is 0
        return done
          status: 'not_found'
          reason: JSON.stringify where
          source: @name

      done null, results[0]

  Select: (fields, where, options, done) ->
    driver.Select @name, fields, where, options, done

  SelectNear: (fields, where, done) ->
    driver.SelectNear @name, fields, where, done

  Save: (blob, done) ->
    if blob.id?
      @Update blob, {id: blob.id}, done
    else
      @Insert blob, done

  Insert: (blob, done) ->
    driver.Insert @name, blob, done

  Update: (blob, where, done) ->
    driver.Update @name, blob, where, done

module.exports = (config) ->

  driver = require('./' + config.dbType)
  tables = driver.tables
  driver = driver(config)

  table: (name) ->
    if !(tables[name]?)
      tables[name] = []

    new Table name
