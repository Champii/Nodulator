Q = require 'q'
async = require 'async'

polyparams = require \polyparams

watchers = []

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
        new @ d
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
      if @_promise?
        @
          .Then ~> cb.apply it, args
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

N.Wrappers = Wrappers
