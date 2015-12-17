
View = (context, fn) ->
  @_type = \View
  if typeof! context is \Function and not fn?
    fn := context
    context := null

  if context?
    for k, v of context
      if typeof! v isnt \Function and typeof! v isnt \Array
        context[k] = new N.Watch.Value v

  RealRender = (arg, done) ->
    viewRoot = DOM.div_!
    first = true

    if not done?
      done := arg
      arg := undefined

    # console.log arg, done

    if not @Set?
      @Set = ~>
        @ <<< it
        RealRender.call @, (_, render) ~>
          render.attrs.anchor = viewRoot.attrs.anchor
          render.Rerender!catch console~error

    N.Watch ~>
      viewRoot.Empty!
      render = viewRoot.AddChild fn.call @, arg
      if first
        first := false
        # render.attrs.anchor = viewRoot.attrs.anchor
        return done null, render

      render.Make!catch console~error
    viewRoot



  ret = (ctx) ~>
    (->) <<< do
      _type: \View
      Render: (done) ~>
        # context := ctx
        args = [done]
        args.unshift ctx if ctx?
        RealRender.apply context, args

  ret.Render = (done) ->
    # console.log done
    RealRender.call context, done

  ret.AttachResource = (res) ->
    # context := res

    # context::Render = RealRender
    res::Render = RealRender
    # console.log res._type
    # socket.on 'update_' + res._type[to -2]*'', ~>
    #   console.log 'tamere'
    #   res::Render.call it, (err, r) -> console.log r; r.Make!then console~log .catch console~error

  ret

View.DOM = DOM
View.Node = Node

N.View = View

N.Render = (func) ->

  N.Watch ->
    DOM.root func! .Make!.catch console~error
 #then console~log
