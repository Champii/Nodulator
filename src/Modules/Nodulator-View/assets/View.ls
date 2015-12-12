class View

  @_type = 'View'

  (@resource) ->
    @resource.Render = (...args) ~> @.__proto__.constructor.Render.apply @resource, args
    @resource::Render = @Render

View.DOM = DOM
View.Node = Node

N.View = View

N.Render = (func) ->
  body = document.getElementsByTagName('body').0
  root = DOM.root func!
  dom = root.Resolve!
  dom
    .then (.0.Render!)
    .then ->
      # console.log it
      body.innerHTML += it
    .catch -> console.error it
