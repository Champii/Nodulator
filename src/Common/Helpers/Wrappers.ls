ChangeWatcher = require './ChangeWatcher'
Q = require 'q'
async = require 'async'

polyparams = require \polyparams

watchers = []

cache = null
class Wrappers

  @_FindDone = -> it |> find-index is-type \Function

  @_WrapPromise = (cb) ->
    d = null

    _FindDone = @_FindDone

    resource = @

    (...args) ->
      idx = _FindDone args

      if not idx?
        d = Q.defer!

        args.push (err, data) ->
          return d.reject err if err?

          d.resolve data

      ret = cb.apply @, args

      if d? and @Init?
        @Init!
        new resource d
      # else if @_promise? and d?
      #   @_promise.then d.promise
      #   @
      else if d? #and @_promise?
        @_promise = d.promise
        @
      else if not d? and ret?.state? and @_type?
        @_promise = ret
        @
      else
        ret

  @_WrapResolvePromise = (cb) ->
    findDone = @_FindDone
    (...args) ->
      doneIdx = findDone args
      oldDone = args[doneIdx]
      if @_promise? and doneIdx?
        @
          .Then ->
            it._promise = null
            cb.apply it, args
          .Catch oldDone
      else
        cb.apply @, args

  @_WrapResolveArgPromise = (cb) ->
    findDone = @_FindDone
    (...args) ->
      doneIdx = findDone args
      oldDone = args[doneIdx]
      async.map args, (arg, done) ->
        if arg?._promise?
          arg
            .Then -> done null it
            .Catch done
        else
          done null arg
      , (err, results) ~>
        return oldDone err if oldDone? and err?

        cb.apply @, results
      @

  @_WrapWatchArgs = (cb) ->
    resource = @
    (...args) ->

      if not @N.Watch.active
        return cb.apply @, args

      watcher = ChangeWatcher.Watch cb, args, @, @N
      if not watcher
        cb.apply @, args
      else
        resource._watchers.push watcher
        watcher

  @_WrapWatch = (cb) ->
    (...args) ->
      first = true
      @N.Watch ~>
        if first
          first := false
          cb.apply @, args

  @_WrapDebugError = (debug, cb) ->
    resource = @

    (...args) ->

      doneIdx = resource._FindDone args
      if not doneIdx?
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
    if not cache?
      cache = require(\./Cache)(@N.config)
    if not @N.config?.cache
      return (...args) ->
        cb.apply @, args

    fullName = name
    (...args) ->
      Resource = @
      name = @name + fullName
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

        if not err? and cached?
          cached = JSON.parse cached
          if is-type \Array cached
            cached = cached |> map -> Resource.Hydrate it
          else
            cached = Resource.Hydrate cached
          return oldDone null, cached

        return oldDone err if err?

        args[doneIdx] = (err, res) ~>
          if err?
            return oldDone err

          if is-type \Array res
            toStore = res
          else
            toStore = obj-to-pairs res |> filter (.0.0 isnt \_) |> pairs-to-obj
          cache.Set name, JSON.stringify(toStore), (err, status) ~>
            return oldDone err if err?

            oldDone null, res

        watchers.push @N.Watch ~>
          cb.apply @, args

  @Reset = ->
    watchers |> each (.Stop!)
    watchers := []

module.exports = Wrappers
# @N.Wrappers = Wrappers
