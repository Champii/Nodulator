_ = require 'underscore'
db = require('mongous').Mongous

ids = {}

module.exports = (config) ->

  class Mongo

    ->
      db().open config.dbAuth.host || 'localhost', config.dbAuth.port || 27017
      console.log config
      if config.dbAuth.user
        db(config.dbAuth.database + '.$cmd').auth config.dbAuth.user, config.dbAuth.pass, (res) ->
          console.log 'Mongo auth: ', res

    Select: (table, fields, where, options, done) ->
      db(config.dbAuth.database + '.' + table).find where, (rows) ->
        done null, rows.documents

    Insert: (table, fields, done) ->
      fields.id = ids[table]++
      db(config.dbAuth.database + '.' + table).insert fields
      done null, fields.id

    Update: (table, fields, where, done) ->
      db(config.dbAuth.database + '.' + table).update {id: fields.id}, fields
      done()

    Delete: (table, where, done) ->
      db(config.dbAuth.database + '.' + table).remove {id: where.id}
      done null, 1

  new Mongo()

module.exports.AddTable = (name) ->
  if !(ids[name]?)
    ids[name] = 1
