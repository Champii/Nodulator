_ = require 'underscore'

tables = {}

class SqlMem

  Select: (table, fields, where, options, done) ->
    if where.id? and typeof where.id is 'string'
      where.id = parseInt where.id

    res = map (-> _({}).extend it), _(tables[table]).where(where)

    if fields isnt '*'
      res = map (-> _.pick(it, fields)), res


    if options.sortBy?
      rev = 0
      if options.sortBy.0 is \-
        options.sortBy = options.sortBy[1 to]*''
        rev = 1
      res = sort-by (.[options.sortBy]), res
      if rev
        res = reverse res
    if options.limit?
      offset = options.offset || 0
      res = res[offset til options.limit]

    done null, res

  Insert: (table, fields, done) ->
    tables[table].push _({}).extend fields

    done null, fields

  Update: (table, fields, where, done) ->
    a = _(tables[table]).chain().findWhere(where).extend fields .value()

    done null a

  Delete: (table, where, done) ->
    tables[table] = _(tables[table]).reject (item) -> item.id is where.id
    done null, 1

  @Reset = ->
    tables := {}
    @

  Drop: (table) ->
    delete tables[table]

  _NextId: (name, done) ->
    id = 0
    if tables[name]?.length
      id = _(tables[name]).max((item) -> item.id).id

    done null, id + 1

module.exports = (config) ->
  res = new SqlMem!

module.exports._Reset = ->
  SqlMem.Reset!
module.exports.AddTable = (name) ->
  if !(tables[name]?)
    tables[name] = []
  tables[name]
