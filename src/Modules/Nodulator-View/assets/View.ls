
View = (context, fn) ->
  @_type = \View
  if typeof! context is \Function and not fn?
    fn := context
    context := null

  RealRender = (arg, done) ->
    viewRoot = DOM.div!
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
          render.Make!catch console~error

    N.Watch ~>
      viewRoot.Empty!
      render = viewRoot.AddChild fn.call @, arg
      if first
        first := false
        return done null, render

      render.attrs.anchor = viewRoot.attrs.anchor
      render.Make!catch console~error
    @



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

  ret

View.DOM = DOM
View.Node = Node

N.View = View

N.Render = (func) ->

  N.Watch ->
    DOM.root func! .Make!.catch console~error
 #then console~log
