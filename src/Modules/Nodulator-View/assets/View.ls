class View

  @_type = 'View'

  (@resource) ->
    @resource.Render = (...args) ~> @.__proto__.constructor.Render.apply @resource, args
    @resource::Render = @Render

View.DOM = DOM
View.Node = Node

N.View = View

N.Render = (func) ->

  DOM.root func! .Make!then console~log .catch console~error
