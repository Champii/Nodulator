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
}

#FIXME: Hack to prevent EADDRINUSE from mocha
port = 3000

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

    @appRoot = path.resolve \.

    @express = express

    @app = @express()

    @app.use bodyParser.urlencoded do
      extended: true

    @app.use bodyParser.json do
      extended: true

    @server = http.createServer @app

    @db = require \./Resource/Connectors

    @client = new Client @app

  Resource: (name, routes, config, _parent) ~>

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
      @resources[name] = resource = ExtendedResource
      @resources[name]._PrepareResource @table(name + \s), config, @app, routes, name
    else
      table = null
      if not config? or (config? and not config.abstract)
        table = @table(name + \s)

      @resources[name] = resource =
        require(\./Resource/Resource) table, config, @app, routes, name

    resource

  Route: require \./Route/Route

  Config: (config) ->
    if @config?
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

    console.log '=> Listening to 0.0.0.0:' + (@config.port || port++)

  Use: (module) ->
    module @

  ExtendDefaultConfig: (config) ->
    @defaultConfig = _(@defaultConfig).extend config

  Bus: require \./Helpers/Bus
  bus: new @::Bus()


  Reset: (done) ->
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
