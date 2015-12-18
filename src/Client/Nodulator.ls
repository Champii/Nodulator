
window.socket = io!

window import require \prelude-ls

class N extends require \../Common/Nodulator

  isClient: true

  Resource: (name, routes, config, _parent) ->
    @resource = require './Resource/Resource' if not @resource?

    return if config?.abstract
    lname = name + \s

    resource = @resource config, routes, lname
    routes?.AttachResource resource

    N[capitalize name] = @resources[lname] = resource

f = (...args) ->

  f.Config! if not f.config?
  f.Resource.apply f, args

f = f <<<< new N

window.N = f
