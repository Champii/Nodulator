N = require '../..'
redis = require \redis

class RedisCache

  ({host = '127.0.0.1', post = 6370, database = 0}) ->

    @client = redis.createClient {host, port}
    @client.select database
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

class MemCache

  ->
    @client = {}

  Get: (name, done) ->
    if @client[name]?
      return done null, reply

    done!

  Set: (name, value, done) ->
    @client[name] = value

    done!

  Delete: (name, done) ->
    delete @client[name]

    done!

  Reset: ->
    @client = {}


class Cache

  ->
    if N.config?.cache?.type is \Redis
      @client = new RedisCache N.config.cache
    else if N.config?.cache?.type is \Mem
      @client = new MemCache

  Get: (name, done) ->
    return done! if not @client?
    @client.Get name, (err, reply) ->
      return done! done err if err?

      done null, reply

  Set: (name, value, done) ->
    return done! if not @client?
    @client.Set name, value, (err, reply) ~>
      return done! done err if err?

      done null, reply

  Delete: (name, done) ->
    return done! if not @client?
    @client.Del name, (err, reply) ~>
      return done! done err if err?

      done null, reply

  Reset: ->
    return if not @client?
    @client.Reset!

module.exports = new Cache
