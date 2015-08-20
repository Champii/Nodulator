Nodulator = require '../..'
ChangeWatcher = require './ChangeWatcher'
Q = require 'q'

class Wrappers

  @_FindDone = (args) ->
    for arg, i in args
      if typeof(arg) is 'function'
        return i

    -1

  @_WrapFlipDone = (cb) ->
    if not Nodulator.config.flipDone
      return cb

    resource = @
    # console.log 'flipdone', @
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
    # console.log 'watchargs', @
    (...args) ->
      if not Nodulator.Watch.active
        return cb.apply @, args

      # console.log 'watch args', @
      if not ChangeWatcher.Watch cb, args, @
        return cb.apply @, args


module.exports = Wrappers
