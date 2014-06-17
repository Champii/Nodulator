_ = require 'underscore'
db = require('mongous').Mongous

ids = {}

module.exports = (config) ->

  class Mongo

    constructor: ->
      db().open config.dbAuth.host || 'localhost', config.dbAuth.port || 27017
      if config.dbAuth.user
        db('blog.$cmd').auth config.dbAuth.user, config.dbAuth.pass, (res) ->
          console.log 'Mongo auth: ', res

    Select: (table, fields, where, options, done) ->
      db(config.database + '.' + table).find where, (rows) ->
        done null, rows.documents

    Insert: (table, fields, done) ->
      fields.id = ids[table]++
      db(config.database + '.' + table).insert fields
      done null, fields.id

    Update: (table, fields, where, done) ->
      db(config.database + '.' + table).update {id: fields.id}, fields
      done()

  new Mongo()

module.exports.AddTable = (name) ->
  if !(ids[name]?)
    ids[name] = 1
