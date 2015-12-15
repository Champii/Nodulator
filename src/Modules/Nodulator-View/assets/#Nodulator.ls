rest = require 'rest'
async = require 'async'
mime = require('rest/interceptor/mime');

require! hacktiv

window.socket = io!

window import require \prelude-ls

Client = rest.wrap(mime)

class Nodulator

  isClient: true
  resources: {}

  Resource: (name, routes, config, _parent) ->
    return if config?.abstract
    lname = name + \s

    resource = _Resource lname, config
    routes?.AttachResource resource

    N[capitalize name] = @resources[lname] = resource

  Watch:    hacktiv
  DontWatch: hacktiv.DontWatch

nodulator = new Nodulator

N = (...args) ->

  N.Resource.apply N, args

window.N = N <<<< nodulator

_Resource = (name, config) ->

  class Resource extends N.Wrappers

    @watchers = []

    @_type = name


    (blob) ->

      @_type = name

      if blob.promise?
        @_promise = blob.promise
        return @

      for k, v of blob
        if typeof! v is \Array
          blob[k] = map (-> new N.resources[k.toLowerCase()] it), v

      if not (db.collection |> find ~> it.id is blob.id)
        db.collection.push blob

      import blob
      @

    _WrapReturnThis: (done) ->
      (arg) ~>
        res = done arg
        res?._promise || res || arg

    Then: ->
      @_promise = @_promise.then @_WrapReturnThis it if @_promise?
      @
    #
    Catch: ->
      @_promise = @_promise.catch @_WrapReturnThis it if @_promise?
      @

    Fail: ->
      @_promise = @_promise.fail @_WrapReturnThis it if @_promise?
      @

    Add: ->
    Save: @_WrapPromise @_WrapResolvePromise (done) ->
      # serie = @Serialize()

    Delete: @_WrapPromise @_WrapResolvePromise (done) ->
      db.Delete {id: @id}, done

    @Create = @_WrapPromise @_WrapResolvePromise @_WrapWatchArgs (blob = {}, done) ->
      resource = @
      if typeof! blob is \Function
        done = blob
        blob = {}

      db.Insert blob, done

    @List = @_WrapPromise @_WrapResolvePromise @_WrapWatchArgs (blob = {}, done) ->
      resource = @
      if typeof! blob is \Function
        done = blob
        blob = {}

      db.Select blob, {}, (err, data) ->
        return done err if err?

        async.mapSeries data, (item, done) ->
          done null new resource item
        , done

    @Fetch = @_WrapPromise @_WrapResolvePromise @_WrapWatchArgs (blob = {}, done) ->
      resource = @
      if typeof! blob is \Function
        done = blob
        blob = {}

      if typeof! blob is \Number
        blob = id: blob

      db.Select blob, {limit: 1}, (err, data) ->
        return done err if err?

        done null new resource data

    Set: @_WrapPromise @_WrapResolvePromise (blob, done) ->
      @ <<< blob
      db.Update blob, {id: @id}, (err, data) ->
        return done err if err?

        done err, data

    @Field = ->
      Default: ->
    @MayHasMany = ->
    @HasMany = ->
    @Init = ->

    @Watch = ->
    Watch: ->
    @_Changed = -> @watchers |> each (.dep._Changed!)

  Resource.db = db = new N.LocalDB Resource

  Resource
