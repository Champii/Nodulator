
View = (resource, fn) ->
  @_type = \View
  if typeof! resource is \Function and not fn?
    fn = resource
    resource = null

  RealRender = (...args, done) ->
    first = true
    anchor = null
    N.Watch ~>
      render = fn.apply @, args
      if first
        first := false
        anchor := render.attrs.anchor
        return done null, render

      render.attrs.anchor = anchor
      render.Make!
        # .then -> console.log 'RENDER', it
        # .catch console~error
    @

  ret = (...args) ~>
    _type: \View
    Render: (done) ~>
      args.push done
      RealRender.apply resource || @, args

  ret.Render = (done) ->
    RealRender.apply resource || @, [done]

  ret.AttachResource = (res) ->
    resource := res
    resource::Render = ->
    resource::Render = RealRender

  ret

View.DOM = DOM
View.Node = Node

N.View = View

N.Render = (func) ->

  DOM.root func! .Make! #then console~log .catch console~error
