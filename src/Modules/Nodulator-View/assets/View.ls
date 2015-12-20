
View = (context, fn) ->
  @_type = \View
  if typeof! context is \Function and not fn?
    fn := context
    context := null

  RealRender = (...args, done) ->
    listener = null

    isInstance = @_type and @id?
    if isInstance
      for k, v of @
        let k = k
          if typeof! v is \Array and k in map (.name), @_schema.assocs
            @[k] = N.Watch.Value v
            assoc = find (.name is k), @_schema.assocs
            N.bus.on \new_ + assoc.type._type, ~>
              if assoc.keyType is \distant
                if it[assoc.foreign] is @id!
                  @[k] @[k]!.concat [new assoc.type it]

    if @ isnt window
      for k, v of @
        if typeof! v isnt \Function and typeof! v isnt \Array and k.0 isnt \_
          @[k] = new N.Watch.Value v


    if isInstance and listener?
      N.bus.removeListeners \update_ + @_type + \_ + @id!, listener

    viewRoot = DOM.div!
    first = true

    if not done?
      done := args
      args := []

    N.Watch ~>
      viewRoot.Empty!
      render = viewRoot.AddChild fn.apply @, args
      if first
        first := false
        if isInstance
          name = @_type
          listener := (changed) ~>
            for k, v of changed when @[k]
              @[k] v
          N.bus.on \update_ + name + \_ + @id!, listener
        return done null, render
      render.Make!catch console~error
    viewRoot

  ret = (...args) ~>
    (->) <<< do
      _type: \View
      Render: (done) ~>
        args_ = args
        args_.push done if done?
        ctx = {} <<< context
        RealRender.apply ctx, args_

  ret._type = \View
  ret.Render = (done) ->
    # console.log done
    # ctx = {} <<< context
    RealRender.call context, done

  ret.AttachResource = (res) ->
    # if res?
    #   for k, v of res
    #     if typeof! v isnt \Function and typeof! v isnt \Array
    #       res[k] = new N.Watch.Value v
    # context := res


    # context::Render = RealRender
    console.log 'Tamere'
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
