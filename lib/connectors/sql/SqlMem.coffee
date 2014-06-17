_ = require 'underscore'

tables = {}

class SqlMem

  constructor: ->

  Select: (table, fields, where, options, done) ->
    if !(tables[table]?)
      tables[table] = []

    if where.id? and typeof where.id is 'string'
      where.id = parseInt where.id

    res = _(tables[table]).where(where)

    done null, res

  Insert: (table, fields, done) ->
    if !(tables[table]?)
      tables[table] = []

    tables[table].push fields

    fields.id = tables[table].length
    done null, tables[table].length

  Update: (table, fields, where, done) ->
    if !(tables[table]?)
      tables[table] = []

    row = _(tables[table]).findWhere(where)

    _(row).extend fields

    done()

module.exports = (config) ->
  new SqlMem()

module.exports.AddTable = (name) ->
  if !(tables[name]?)
    tables[name] = []
