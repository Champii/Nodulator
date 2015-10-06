require! {
  underscore: _
  fs
  path
  hacktiv
  \prelude-ls : {each, obj-to-pairs}
  \./Helpers/Debug
}

debug-nodulator = new Debug 'N::Core'

class N

  app: null
  express: null
  server: null
  resources: {}
  directives: {}
  routes: {}
  config: null
  table: null
  authApp: false
  consoleMode: false
  defaultConfig:
    dbType: \SqlMem
    flipDone: false

  ->
    @Init()

  Init: ->

    debug-nodulator.Log \Init

    @appRoot = path.resolve \.

    @db = require \./Resource/Connectors

    debug-nodulator.Log 'Init ended'

  Resource: (name, routes, config, _parent) ~>

    resource = null
    name = name.toLowerCase()
    if @resources[name]?
      debug-nodulator.Log "Existing resource : #{name}"
      return @resources[name]

    if routes? and not routes.prototype
      config = routes
      routes = null

    @Config() if not @config? # config of N instance, not resource one

    if not _parent? and (not routes? or routes.prototype not instanceof @Route)
      routes = @Route

    if _parent?
      class ExtendedResource extends _parent
      @resources[name] = resource := ExtendedResource
      @resources[name]._PrepareResource @table(name + \s), config, @app, routes, name, _parent
    else
      table = null
      if not config? or (config? and not config.abstract)
        table = @table(name + \s)

      @resources[name] = resource :=
        require(\./Resource/Resource) table, config, @app, routes, name

    getParentChain = ->
      | it?._parent? => " <= #{that.name}" + getParentChain that
      | _   => ''

    debug-nodulator.Log "Resource added : #{name + getParentChain @resources[name]}"

    resource

  Route: require \./Route/Route

  Config: (config) ->
    debug-nodulator.Warn "Start main config"
    if @config?
      debug-nodulator.Warn "Aleady configured"
      return

    @config = config || @defaultConfig

    @defaultConfig
      |> obj-to-pairs
      |> each ~> @config[it.0] = it.1 if not @config[it.0]?

    @table = @db(@config).table

  Use: (module) ->
    debug-nodulator.Log "Loading module"
    m = module @
    debug-nodulator.Log "Loaded module: #{m.name}"
    m

  Console: ->
    @consoleMode = true

  ExtendDefaultConfig: (config) ->
    @defaultConfig = _(@defaultConfig).extend config

  Bus: require \./Helpers/Bus
  bus: new @::Bus()

  # Reset: (done) ->
  #   debug-nodulator.Warn "Reset"
  #
  #   @inited = {}
  #   @db._reset() if @db?
  #   @table = null
  #   @resources = {}
  #   @config = null
  #
  #   if @server?
  #     @app = null
  #     @server.close()
  #     @server = null
  #
  #   @db._reset() if @db?
  #   @Init()
  #
  #   done() if done?

  Watch:    Hacktiv
  DontWatch: Hacktiv.DontWatch

  _ListEndpoints: (done) ->
    endpoints = []
    for endpoint in @app._router.stack
      if endpoint.route?
        res = {}
        res[endpoint.route.path] = [key for key of endpoint.route.methods]
        endpoints.push res
    done(endpoints) if done?


Nodulator = new N

f = (...args) ->

  f.Config! if not f.config?
  f.Resource.apply f, args

f = f <<<< Nodulator
f.Reset = (done) ->
  debug-nodulator.Warn "Reset"

  @inited = {}
  Nodulator.inited = {}
  @db._reset() if @db?
  Nodulator.db._reset() if Nodulator.db?
  @table = null
  Nodulator.table = null
  @resources = {}
  Nodulator.resources = {}
  @config = null
  Nodulator.config = null

  if @server?
    @app = null
    Nodulator.app = null
    @server.close()
    @server = null
    Nodulator.server = null

  @db._reset() if @db?
  Nodulator.db._reset() if Nodulator.db?
  @Init()

  done() if done?
module.exports = f
