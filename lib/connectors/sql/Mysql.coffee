_ = require 'underscore'
mysql = require 'mysql'

module.exports = (config) ->

  connection = mysql.createConnection
    host     : config.dbAuth.host || 'localhost'
    port     : config.dbAuth.port || 3306
    user     : config.dbAuth.user || ''
    password : config.dbAuth.pass || ''
    database : config.dbAuth.database || ''
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
          limit = ''
          if options.offset?
            limit += options.offset + ', '
            limit += options.limit - options.offset
          else
            limit += options.limit
          query += ' limit ' + limit

      connection.query query, where, (err, rows) ->
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

    Delete: (table, where, done) ->
      query = 'delete from ' + table + ' where ' + _(where).map((value, key) ->
        return mysql.escapeId(key) + ' = ' + mysql.escape(value)
      ).join(' and ')

      connection.query query, {}, (err, results) ->
        return done err if err?

        done null, results.affectedRows

    _MakeSQLCondition: (value, key) ->
      safeKey = mysql.escapeId key

      # normal case A = B
      if !_.isObject value
        return safeKey + ' = ' + mysql.escape value

      op = if value.sup then ' > ' else ' < '
      return safeKey + op + mysql.escape value.val

  new Mysql

module.exports.AddTable = (name) ->
