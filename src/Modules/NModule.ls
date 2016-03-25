class NModule

  config: null
  defaultConfig: {}

  (config) ->
    @Config config
    @Init!

  Init: -> ...

  PostConfig: ->

  Config: (config) ->
    return if @config?

    console.log "Configure #{@name}"

    @config = @defaultConfig
    @config <<< config

module.exports = NModule
