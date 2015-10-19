redis = require \redis

class Cache

  ->
    @client = redis.createClient!
    @client.select 15
    @client.flushdb()

  Get: (name, done) ->
    @client.get name, (err, reply) ->
      return done err if err?

      done null, reply

  Set: (name, value, done) ->
    @client.set name, value, (err, reply) ~>
      return done err if err?

      @client.expire(name, 3600);
      done null, reply

  Delete: (name, done) ->
    @client.del name, (err, reply) ~>
      return done err if err?

      done null, reply

  Reset: ->
    @client.flushdb()

module.exports = new Cache
