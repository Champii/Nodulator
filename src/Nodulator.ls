require! {
  underscore: _
  fs
  path
  http
  '../test/common/client': Client
  express
  hacktiv
  \body-parser : bodyParser
  \express-session : express-session
  \prelude-ls : {each, obj-to-pairs}
  \./Helpers/Debug
}

debug = require 'debug'

#FIXME: Hack to prevent EADDRINUSE from mocha
port = 3000


# debug-test = debug 'Nodulator::Core'
# for i from 0 to 32
#   debug-test.color = debug.useColors && debug.colors[i]
#   debug-test("lol #i")


debug-nodulator = new Debug 'Nodulator::Core'
# debug-nodulator.Log = debug
#   ..color = debug.useColors && debug._colors.green
#
# debug-nodulator.Warn = debug 'Nodulator::Core::Warn'
#   ..color = debug.useColors && debug._colors.yellow
#
# debug-nodulator-error = debug 'Nodulator::Core::Error'
#   ..color = debug.useColors && debug._colors.red

class Nodulator

  app: null
  express: null
  server: null
  resources: {}
  directives: {}
  routes: {}
  config: null
  table: null
  authApp: false
  defaultConfig:
    dbType: \SqlMem
    flipDone: false

  ->
    @Init()

  Init: ->


    debug-nodulator.Log \Init

    @appRoot = path.resolve \.

    @express = express

    @app = @express()

    @app.use bodyParser.urlencoded do
      extended: true

    @app.use bodyParser.json do
      extended: true

    debug-nodulator.Log 'Creating server'

    @server = http.createServer @app

    @db = require \./Resource/Connectors

    @client = new Client @app

    debug-nodulator.Log 'Init ended'

  Resource: (name, routes, config, _parent) ~>

    resource = null
    name = name.toLowerCase()
    if @resources[name]?
      return @resources[name]

    if routes? and not routes.prototype
      config = routes
      routes = null

    @Config() if not @config? # config of Nodulator instance

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

    sessions =
      key: \Nodulator
      secret: \Nodulator
      resave: true
      saveUninitialized: true

    if @config?.store?.type is \redis
      RedisStore = require(\connect-redis)(express-session)

      @sessionStore = new RedisStore do
        host: @config.store.host || \localhost

      sessions.store = @sessionStore

    @app.use express-session sessions

    @table = @db(@config).table

    @server.listen @config.port || port

    @bus.emit \listening

    debug-nodulator.Log "=> Listening to 0.0.0.0: #{(@config.port || port++)}"

  Use: (module) ->
    debug-nodulator.Log "Loading module"
    m = module @
    debug-nodulator.Log "Loaded module: #{m.name}"
    m

  ExtendDefaultConfig: (config) ->
    @defaultConfig = _(@defaultConfig).extend config

  Bus: require \./Helpers/Bus
  bus: new @::Bus()

  Reset: (done) ->
    debug-nodulator.Warn "Reset"

    @inited = {}
    if not @server?
      @Init()
      done() if done?
      return

    @resources = {}
    @config = null
    @table = null

    @db._reset() if @db?
    @Init()

    done() if done?

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

module.exports = new Nodulator
