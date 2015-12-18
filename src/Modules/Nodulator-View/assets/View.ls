
View = (context, fn) ->
  @_type = \View
  if typeof! context is \Function and not fn?
    fn := context
    context := null



  RealRender = (arg, done) ->
    for k, v of @
      if typeof! v isnt \Function and typeof! v isnt \Array
        @[k] = new N.Watch.Value v

    console.log \Context @
    viewRoot = DOM.div_!
    first = true

    if not done?
      done := arg
      arg := undefined

    N.Watch ~>
      viewRoot.Empty!
      render = viewRoot.AddChild fn.call @, arg
      if first
        first := false
        console.log 'FIRST', @
        if @_type? and @id?
          name = @_type[to -2]*''
          N.bus.on \update_ + name + \_ + @id, (changed) ~>
            console.log 'UPDATE' name, @id, changed
            for k, v of changed when @[k]
              @[k] v
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
    # if res?
    #   for k, v of res
    #     if typeof! v isnt \Function and typeof! v isnt \Array
    #       res[k] = new N.Watch.Value v
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
