_ = require 'underscore'
mysql = require 'mysql'

env = require '../../../../settings/environement.js'
Settings = require 'settings'
config = new Settings(require '../../../../settings/config', {env: env.forceEnv})

connection = mysql.createConnection
  host     : config.mysql.host
  user     : config.mysql.user
  password : config.mysql.password
  database : config.mysql.database
  typeCast: (field, next) ->
    if field.type is 'TINY' and field.length is 1
      return field.string() is '1'
    return next()

connection.on 'error', ->
  console.error 'MYSQL ERROR'

class Mysql

  constructor: ->

  Select: (table, fields, where, options, done) ->
    f = fields
    if Array.isArray fields
      f = fields.join(',')

    query = 'select ' + f + ' from ' + table

    hasConditions = _(where).size() > 0 if where?

    if (hasConditions)
      query += ' where ' + _(where).map(@_MakeSQLCondition).join(' and ');

    if options?

      if options.sortBy?
        query += ' order by ' + options.sortBy

        if options.reverse
          query += ' desc'

      if options.limit?
        query += ' limit ' + options.limit

    connection.query query, where, (err, rows) ->
      return done err if err?

      done null, rows

  SelectNear: (table, fields, where, done) ->
    f = fields
    if Array.isArray fields
      f = fields.join(',')

    f += ', (6371 * acos(cos(radians(' + where.lat + ')) * cos(radians(lat)) * cos(radians(lng) - radians(' + where.lng + ')) + sin(radians(' + where.lat + ')) * sin(radians(lat)))) AS distance'

    query = 'select ' + f + ' from ' + table + ' HAVING distance < 2500 ORDER BY distance LIMIT 0 , 20'


    connection.query query, {}, (err, rows) ->
      return done err if err?

      done null, rows

  Insert: (table, fields, done) ->
    query = 'insert into ' + table + ' set ?'

    connection.query query, fields, (err, results) ->
      return done err if err?

      done null, results.insertId

  Update: (table, fields, where, done) ->
    query = 'update ' + table + ' set ? where ' + _(where).map((value, key) ->
      return mysql.escapeId(key) + ' = ' + mysql.escape(value)
    ).join(' and ')

    connection.query query, fields, (err, results) ->
      return done err if err?

      done null, results.affectedRows

  _MakeSQLCondition: (value, key) ->
    safeKey = mysql.escapeId key

    # normal case A = B
    if !_.isObject value
      return safeKey + ' = ' + mysql.escape value

    op = if value.sup then ' > ' else ' < '
    return safeKey + op + mysql.escape value.val

    # when passed an array, interpret as an "IN" statement
    # http://dev.mysql.com/doc/refman/5.0/en/comparison-operators.html#function_in
    # return safeKey + ' in (' + _(value).map((element) -> mysql.escape element).join(', ') + ')'

module.exports = new Mysql
