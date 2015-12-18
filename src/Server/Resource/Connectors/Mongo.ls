_ = require 'underscore'
db = require('mongous').Mongous

ids = {}

module.exports = (config) ->

  class Mongo

    ->
      db().open config.host || 'localhost', config.port || 27017

      if config.user
        db(config.database + '.$cmd').auth config.user, config.pass, (res) ->

    Select: (table, fields, where, options, done) ->

      db(config.database + '.' + table).find where, (rows) ->
        done null, rows.documents

    Insert: (table, fields, done) ->
      db(config.database + '.' + table).insert fields
      done null, fields

    Update: (table, fields, where, done) ->
      db(config.database + '.' + table).update {id: fields.id}, fields
      done()

    Delete: (table, where, done) ->
      db(config.database + '.' + table).remove {id: where.id}
      done null, 1

    Drop: (table) ->
      db(config.database + '.$cmd').find({drop: table},1)

    _NextId: (name, done) ->
      db(config.database + '.' + name).find {}, {}, {sort: {id: -1}, lim: 1}, ->
        done null, +it.documents[0]?.id + 1 || 1

  new Mongo()

module.exports.AddTable = (name, config, done) ->
