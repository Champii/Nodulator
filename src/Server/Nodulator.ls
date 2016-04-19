require! {
  underscore: _
  fs
  path
  hacktiv
}

global import require \prelude-ls

class N extends require \../Common/Nodulator

  config: null
  consoleMode: false
  defaultConfig:
    db: type: \SqlMem
    cache: false
    modules: {}
    port: 3000
  isServer: true
  modules: {}

  ->
    super!
    @Init()

  Init: ->
    @appRoot = path.resolve \.
    @libRoot = path.resolve __dirname, \../../

  Resource: ->
    @resource = require './Resource/Resource' if not @resource?
    super ...

  Route: require \./Route/Route

  Config: (config) ->

    super ...

    return if not @config.modules?

    for name, conf of @config.modules
      Module = require(path.resolve @libRoot, "src/Modules/Nodulator-#{capitalize name}")
      @modules[name] = new Module conf
      @config.modules[name] <<< @modules[name].config

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

  PostConfig: ->
    for name, module of @modules
      module.PostConfig!
    map (.Init!), values @resources

  _ListEndpoints: (done) ->
    endpoints = []
    for endpoint in @app._router.stack
      if endpoint.route?
        res = {}
        res[endpoint.route.path] = [key for key of endpoint.route.methods]
        endpoints.push res
    done(endpoints) if done?

f = ((...args) ->
  f.Config {} if not f.config?
  f.Resource.apply f, args) <<<< new N

module.exports = f
