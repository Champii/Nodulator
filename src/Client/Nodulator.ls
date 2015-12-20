
window.socket = io!

prelude = require \prelude-ls
prelude.div_ = prelude.div
prelude.span_ = prelude.span
delete prelude.div
delete prelude.span
window import prelude


class N extends require \../Common/Nodulator

  isClient: true
  defaultConfig:
    db: type: \ClientDB
    cache: false

  Resource: (name, routes, config, _parent) ->
    @resource = require './Resource/Resource' if not @resource?
    super ...


    # @Config! if not @config?
    # return if config?.abstract
    #
    # resource = @resource config, routes, name
    # routes?.AttachResource resource
    #
    # N[capitalize name] = @resources[name] = resource

f = (...args) ->

  f.Config! if not f.config?
  f.Resource.apply f, args

f = f <<<< new N

window.N = f
module.exports = f
