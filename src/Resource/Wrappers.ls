N = require '../..'
ChangeWatcher = require './ChangeWatcher'
Q = require 'q'
Debug = require \../Helpers/Debug
polyparams = require \polyparams
cache = require \./Cache

debug-cache = new Debug 'N::Resource::Cache'

watchers = []

class Wrappers

  @_FindDone = (args) ->
    for arg, i in args
      if typeof(arg) is 'function'
        return i

    -1

  @_WrapFlipDone = (cb) ->
    if not N.config.flipDone
      return cb

    resource = @

    (...args) ->

      doneIdx = resource._FindDone args
      if doneIdx is -1
        return cb.apply @, args

      oldDone = args[doneIdx]

      args[doneIdx] = (err, data) ->
        if err?
          resource.error err
          return oldDone data, err

        resource.error null, false

        oldDone data, err

      cb.apply @, args

  @_WrapPromise = (cb) ->
    d = null

    _FindDone = @_FindDone

    (...args) ->
      idx = _FindDone args

      if idx is -1
        d = Q.defer()

        args.push (err, data) ->
          return d.reject err if err?

          d.resolve data

      ret = cb.apply @, args
      d?.promise || ret

  @_WrapWatchArgs = (cb) ->
    (...args) ->

      if not N.Watch.active
        return cb.apply @, args

      if not ChangeWatcher.Watch cb, args, @
        return cb.apply @, args

  @_WrapDebugError = (debug, cb) ->

    resource = @

    (...args) ->

      doneIdx = resource._FindDone args
      if doneIdx is -1
        return cb.apply @, args

      oldDone = args[doneIdx]

      args[doneIdx] = (err, data) ->
        if err?
          debug JSON.stringify err
          # Debug.UnDepth!
          return oldDone err, data

        oldDone err, data

      cb.apply @, args

  @_WrapParams = (...types) ->

    (...args) ->
      _cb = polyparams.apply @, types
      _cb.apply @, args

  @_WrapCache = (name, cb) ->

    fullName = name
    (...args) ->
      Resource = @
      name = @lname + fullName
      doneIdx = @_FindDone args
      _oldDone = args[doneIdx]
      first = true
      oldDone = (err, res) ->
        if first
          first := false
          _oldDone err, res
        else
          0


      if is-type \Array args[0] or is-type \Object args[0]
        name += JSON.stringify args[0]
      else if is-type \Number args[0]
        name += args[0]
      else
        name += '{}'

      cache.Get name, (err, cached) ~>
        # console.log 'Got', name, err, cached, oldDone

        if not err? and cached?
          debug-cache.Warn 'Cache answered for ' + name
          cached = JSON.parse cached
          if is-type \Array cached
            cached = cached |> map -> Resource.Hydrate it
          else
            cached = Resource.Hydrate cached
          return oldDone null, cached

        return oldDone err if err?

        args[doneIdx] = (err, res) ~>
          if err?
            # return cache.Delete name, ->
            #   debug-cache.Warn 'Cache deleted for ' + name
            #   watcher?.Stop!
            return oldDone err

          if is-type \Array res
            toStore = res
          else
            toStore = obj-to-pairs res |> filter (.0.0 isnt \_) |> pairs-to-obj
          cache.Set name, JSON.stringify(toStore), (err, status) ~>
            return oldDone err if err?

            debug-cache.Log 'Cache updated for ' + name

            oldDone null, res

        watchers.push N.Watch ~>
          cb.apply @, args

  @Reset = ->
    watchers |> each (.Stop!)
    watchers := []

module.exports = Wrappers
