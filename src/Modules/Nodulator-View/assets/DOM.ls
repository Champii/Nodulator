require! {
  underscore: _
  q
  async
}

tags = <[a abbr address area article aside audio b base bdo blockquote body br button canvas caption cite code col colgroup datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form head header h1 h2 h3 h4 h5 h6 hr html i iframe img ins input kbd keygen label legend li link map mark menu menuitem meta meter nav object ol optgroup option output p param pre progress q s samp script section select small source span strong style sub summary sup table td th tr textarea time title track u ul var video]>
selfClosingTags = <[area base br col command embed hr img input keygen link meta param source track wbr]>
customTags = <[root text]>

window.DOM = {}

class Node

  (@name, @attrs = {}, ...@origChildren) ->
    @_type = 'Node'
    throw "Unknown Tag: #{name}" if @name not in tags and @name not in customTags

    if @name in customTags
      switch @name
        | \text =>
          @text = @attrs
          @Resolve = -> @text

    if @attrs? and (typeof! @attrs isnt \Object or @attrs._promise? or @attrs.then? or @name is \root or @attrs._type is \Node)
      @origChildren.unshift @attrs
      @attrs = {}

    @origChildren = @_Flatten @origChildren

  _Flatten: (array) ->
    newArray = []

    for item in array
      if typeof! item is \Array
        newArray = newArray.concat item
      else
        newArray.push item

    newArray

  # Change every child into a Renderable Node
  Resolve: ->
    d = q.defer!
    async.mapSeries @origChildren, @~ResolveType, (err, childs) ~>
      return d.reject err if err?

      childs = @_Flatten childs
      @children = childs
      async.mapSeries childs, (item, done) ->
        promise = item.Resolve!

        if promise.then?
          promise.then -> done null it
          promise.catch done
        else
          done null promise
      ,(err, childs) ~>
        return d.reject err if err?

        d.resolve @children

    return d.promise

  MakeAttrStr: ->
    return '' if not @attrs?
    res = ''
    for k, v of @attrs when k isnt \click
      res += " #k=\"#v\""
    res

  ManageSelfClosing: ->
    d = q.defer!
    if @origChildren.length
      return d.reject "Self closing tags cannot have children: #{@name}"

    d.resolve @node += ' />'
    return d.promise

  ResolveType: (child, done)->
    switch
      | typeof! child is \String      => @_String child, done
      | child.then?                   => @_Promise child, done
      | child.Init?                   => @_Resource child, done
      | child._promise?               => @_ResourcePromise child, done
      | child.Then?                   => @_ResourceInst child, done
      | child._type is \Node          => @_Node child, done
      | child.Render?                 => @_View child, done
      | typeof! child is \Array       => @_Array child, done
      | _                             => @_String '' + child, done

  _String:    (text, done)      -> done null new Node \text text
  _View:      (view, done)      -> @ResolveType view.Render!, done
  _Node:      (node, done)      -> done null node
  _Array:     (array, done)     -> async.mapSeries array, @~ResolveType, done
  _Resource:  (resource, done)  -> @ResolveType resource.Render!, done

  _Promise: (promise, done) ->
    promise
      .then  -> done null, it
      .catch -> done it

  _ResourceInst: (resourceInst, done) ->
    throw "No Render() on #{resourceInst._type}. Attach view first" if not resourceInst.Render?
    done null resourceInst.Render!

  _ResourcePromise: (resourcePromise, done) ->
    resourcePromise
      .Then  ~>
        if it.Render?
          return done null it.Render!

        @ResolveType it, done
      .Catch -> done it

  _ResolveChild: (child, done) ->
    promise = child.Render!

    promise.then -> done null it
    promise.catch done

  Process: ->
    d = q.defer!
    if @name is \text
      d.resolve @text
      return d.promise

    async.mapSeries @children, @_ResolveChild, (err, childs) ~>
      return d.reject err if err?

      @node += childs |> fold (+), ''
      @node += "</#{@name}>"

      d.resolve @node

    return d.promise

  Render: ->
    @node = "<#{@name}#{@MakeAttrStr!}"

    if @name in selfClosingTags
      return @ManageSelfClosing!

    @node += '>'

    return @Process @node

tags |> each (tag) ->
  DOM[tag] = (...args) ->  new (Node.bind.apply Node, [Node, tag].concat args)

DOM.root = (...args) -> new (Node.bind.apply Node, [Node, \root].concat args)

window.Node = Node
