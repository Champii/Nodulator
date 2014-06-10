_ = require 'underscore'

# env = require '../../../../settings/environement.js'
# Settings = require 'settings'
# config = new Settings(require '../../../../settings/config', {env: env.forceEnv})

tables = {}

class SqlMem

  constructor: ->

  Select: (table, fields, where, options, done) ->
    if where.id? and typeof where.id is 'string'
      where.id = parseInt where.id

    res = _(tables[table]).where(where)

    done null, res

  SelectNear: (table, fields, where, done) ->
    done null, []

  Insert: (table, fields, done) ->

    tables[table].push fields

    fields.id = tables[table].length
    done null, tables[table].length

  Update: (table, fields, where, done) ->
    row = _(tables[table]).findWhere(where)

    _(row).extend fields

    done()

module.exports = new SqlMem
module.exports.tables = tables
