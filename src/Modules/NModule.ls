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

    @config = @defaultConfig
    @config <<< config

module.exports = NModule
