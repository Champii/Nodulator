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

    @config = @DeepMerge @defaultConfig, config

  DeepMerge: (destination, source) ->
    for k, v of source
      if v && v.constructor && v.constructor === Object
        destination[k] = destination[k] || {};
        @DeepMerge destination[k], v
      else
        destination[k] = v
    destination

module.exports = NModule
