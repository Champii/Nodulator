require! {
  underscore: _
  fs
  path
  hacktiv
}

class N extends require \../Common/Nodulator

  config: null
  consoleMode: false
  defaultConfig:
    db: type: \SqlMem
    cache: false
    flipDone: false
  isServer: true

  ->
    super!
    @Init()

  Init: ->
    @appRoot = path.resolve \.

  Resource: ->
    @resource = require './Resource/Resource' if not @resource?
    super ...

  Config: (config) ->
    if @config?
      return

    @debug-nodulator.Warn "Main config"

    @config = config || @defaultConfig

    @defaultConfig
      |> obj-to-pairs
      |> each ~> @config[it.0] = it.1 if not @config[it.0]?

  Use: (module) ->
    @debug-nodulator.Log "Loading module"
    m = module @
    @debug-nodulator.Log "Loaded module: #{m.name}"
    m

  ExtendDefaultConfig: (config) ->
    @defaultConfig = _(@defaultConfig).extend config

  Route: require \./Route/Route

  Reset: (done) ->
    @debug-nodulator.Warn "Reset"

    cache = require \../Common/Helpers/Cache.ls
    if cache.client?
      cache.Reset!

    require \../Common/Helpers/Wrappers.ls .Reset!
    require \./Resource/Connectors .Reset!

    @inited = {}
    @resources = {}
    @config = null

    if @server?
      @app = null
      @server.close()
      @server = null

    @Init()

    done() if done?

  _ListEndpoints: (done) ->
    endpoints = []
    for endpoint in @app._router.stack
      if endpoint.route?
        res = {}
        res[endpoint.route.path] = [key for key of endpoint.route.methods]
        endpoints.push res
    done(endpoints) if done?

f = (...args) ->

  f.Config! if not f.config?
  f.Resource.apply f, args

f = f <<<< new N

module.exports = f
