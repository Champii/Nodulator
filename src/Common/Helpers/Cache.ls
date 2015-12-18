redis = require \redis
Debug = require '../Helpers/Debug'

debug-cache = new Debug 'N::Resource::Cache'

class RedisCache

  ({host = '127.0.0.1', port = 6379, database = 0}) ->

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

  (config) ->
    if config?.cache?.type is \Redis or config?.cache is \Redis
      debug-cache.Warn 'Redis cache init'
      @client = new RedisCache config.cache if not is-type \String config.cache
      @client = new RedisCache {} if is-type \String config.cache
    else if config?.cache?.type is \Mem or config?.cache is \Mem
      debug-cache.Warn 'Mem cache init'
      @client = new MemCache
    else
      debug-cache.Warn 'No cache activated'

  Get: (name, done) ->
    return done! if not @client?
    @client.Get name, (err, reply) ->
      return done! done err if err?

      debug-cache.Warn 'Cache answered for ' + name
      done null, reply

  Set: (name, value, done) ->
    return done! if not @client?
    @client.Set name, value, (err, reply) ~>
      return done! done err if err?

      debug-cache.Warn 'Cache updated for ' + name
      done null, reply

  Delete: (name, done) ->
    return done! if not @client?
    @client.Delete name, (err, reply) ~>
      return done! done err if err?

      debug-cache.Warn 'Cache deleted for ' + name
      done null, reply

  Reset: ->
    return if not @client?
    @client.Reset!

module.exports = -> new Cache it
