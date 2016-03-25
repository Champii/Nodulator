require! {
  hacktiv: Hacktiv
  \./Helpers/Debug
}

class N

  resources: {}
  inited: {}

  ->
    @debug-nodulator = new Debug 'N::Core'
    @Init()

  Init: ->

  Resource: (name, routes, config, _parent) ->
    if not @config?
      throw new Error "Trying to create Resource before N.Config()"

    getParentChain = ->
      | it?._parent? => " <= #{that.name}" + getParentChain that
      | _   => ''

    @debug-nodulator.Log "Start creating resource: #{name + getParentChain @resources[name]}"

    resource = null
    name = name.toLowerCase()
    if @resources[name]?
      @debug-nodulator.Log "Existing resource : #{name}"
      return @resources[name]

    if routes? and not routes.prototype
      config = routes
      routes = null

    if config?
      config.db = {} if not config.db?

      obj-to-pairs @config.db |> each ->
        | not config.db[it.0]? => config.db[it.0] = it.1

    config = {db: @config.db} if not config?

    if _parent?
      class ExtendedResource extends _parent

      @resources[name] = resource := ExtendedResource
      @resources[name]._PrepareResource config, routes, name, _parent
    else
      @resources[name] = resource :=
        @resource config, routes, name, @

    @debug-nodulator.Log "Resource added : #{name + getParentChain @resources[name]}"

    resource

  Route: {}

  Config: (config) ->
    if @config?
      throw new Error "Already configured."

    @debug-nodulator.Warn "Main config"

    @config = @defaultConfig
    @config <<< config


  Use: (module) ->

  Console: (@consoleMode = true) ->

  ExtendDefaultConfig: (config) -> ...

  Bus: require \./Helpers/Bus
  bus: new @::Bus()

  Watch:    Hacktiv
  DontWatch: Hacktiv.DontWatch

  _ListEndpoints: (done) ->

module.exports = N
