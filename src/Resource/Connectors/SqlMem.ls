_ = require 'underscore'

tables = {}

class SqlMem

  Select: (table, fields, where, options, done) ->
    if where.id? and typeof where.id is 'string'
      where.id = parseInt where.id

    res = _(tables[table]).where(where)

    if options.limit?
      offset = options.offset || 0
      res = res[offset til options.limit]

    done null, res

  Insert: (table, fields, done) ->
    tables[table].push fields

    # fields.id = tables[table].length
    done null, fields

  Update: (table, fields, where, done) ->
    row = _(tables[table]).findWhere(where)

    _(row).extend fields

    done()

  Delete: (table, where, done) ->
    tables[table] = _(tables[table]).reject (item) -> item.id is where.id
    done null, 1

  @Reset = ->
    tables := {}
    @

  Drop: (table) ->
    delete tables[table]

  _NextId: (name, done) ->
    done null, _(tables[name]).max((item) -> item.id) + 1

module.exports = (config) ->
  res = new SqlMem!

module.exports._Reset = ->
  SqlMem.Reset!
module.exports.AddTable = (name) ->
  if !(tables[name]?)
    tables[name] = []
  tables[name]
