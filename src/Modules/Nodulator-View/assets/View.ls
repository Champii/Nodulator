

proxyHandler =
  get: (target, name) ->
    # console.log 'GET' target, name
    target[name]?!

  set: (target, name, val) ->
    # console.log 'SET' target, name, val, target[name]
    if not target[name]?
      target[name] = new N.Watch.Value val
    target[name] val

View = (context, fn) ->
  @_type = \View
  if typeof! context is \Function and not fn?
    fn := context
    context := null
  else
    for k, v of context
      context[k] = new N.Watch.Value v
    context := new Proxy context, proxyHandler

  RealRender = (...args, done) ->
    # console.log 'Rerender', @
    listener = null

    for arg, i in args
      if is-type \Object arg
        for k, v of arg
          arg[k] = new N.Watch.Value v
        args[i] := new Proxy arg, proxyHandler


    isInstance = @_type and @id?
    if isInstance
      # console.log 'REALRENDER IS INSTANCE' @
      for k, v of @
        let k = k
          if typeof! v is \Array and k in map (.name), @_schema.assocs
            @[k + \_] = N.Watch.Value v
            assoc = find (.name is k), @_schema.assocs
            N.bus.on \new_ + assoc.type._type, ~>
              if assoc.keyType is \distant
                if it[assoc.foreign] is @id
                  @[k + \_] @[k].concat [new assoc.type it]

    # if @ isnt window
    #   for k, v of @
    #     console.log 'ALLOC' k, v
    #     @[k] = v
        # if (typeof! v isnt \Function and k.0 isnt \_) or (typeof! v is \Array and !isInstance)
        #   @[k + \_] = new N.Watch.Value v


    if isInstance and listener?
      N.bus.removeListeners \update_ + @_type + \_ + @id, listener

    viewRoot = DOM.div!
    first = true

    if not done?
      done := args
      args := []

    N.Watch ~>
      # console.log 'WATCH !!!!' @
      viewRoot.Empty!
      render = viewRoot.AddChild fn.apply @, args
      if first
        # console.log 'First?', first
        first := false
        if isInstance
          name = @_type
          listener := (changed) ~>
            for k, v of changed when @[k]?
              # @[k + \_] v
              @[k] = v
            # console.log 'AFTER' @
            @Changed!
          N.bus.on \update_ + name + \_ + @id, listener
        return done null, render
      render.Make!catch console~error
    viewRoot

  ret = (...args) ~>
    (->) <<< do
      _type: \View
      Render: (done) ~>
        args_ = args
        args_.push done if done?
        # ctx = {} <<< context
        RealRender.apply context, args_

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


    # context::Render = RealRender
    res::Render = RealRender
    res::Res = res
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
