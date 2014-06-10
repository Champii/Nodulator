_ = require 'underscore'
async = require 'async'


class Db

  table: null

  constructor: (@table) ->

  Fetch: (id, done) ->
    cities.Find id, done

  List: (done) ->
    cities.Select 'id', {}, {}, done

  Save: (blob, done) ->
    cities.Save blob, done

module.exports = Db
