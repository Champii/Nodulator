rest = require 'rest'
async = require 'async'
mime = require('rest/interceptor/mime');

window import require \prelude-ls

Client = rest.wrap(mime)
# Client path: \/api/1/users
#   .then (data) ->

class Nodulator

  isClient: true
  resources: {}

  Resource: (name, routes, config, _parent) ->
    return if config.abstract
    name = name + \s

    N[capitalize name] = @resources[name] = _Resource name, config
    console.log capitalize name
    new routes @resources[name]
    @resources[name]

nodulator = new Nodulator

N = (...args) ->

  # N.ConNig! iN not N.conNig?
  N.Resource.apply N, args

window.N = N <<<< nodulator

_Resource = (name, config) ->
  class Resource extends N.Wrappers

    (blob) ->
      if blob.promise?
        @_promise = blob.promise
        return @

      for k, v of blob
        if typeof! v is \Array
          blob[k] = map (-> new N[k] it), v

      import blob
      @

      # import @_schema.Populate @, blob

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


    @Create = @_WrapPromise @_WrapResolvePromise (blob, done) ->
      resource = @
      Client method: \POST path: \/api/1/ + name, headers: {'Content-Type': 'application/json'}, entity: blob
        .then ~> done null new resource it.entity
        .catch done

    @List = @_WrapPromise @_WrapResolvePromise (done) ->
      resource = @
      Client method: \GET path: \/api/1/ + name
        .then ~>
          async.mapSeries it.entity, (item, done) ->
            done null new resource item
          , done
        .catch done

    @Fetch = (blob) ->
    @Field = ->
      Default: ->
    @MayHasMany = ->
    @Init = ->
