require! {
  underscore: _
  q
  async
}

tags = <[a abbr address area article aside audio b base bdo blockquote body br button canvas caption cite code col colgroup datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form head header h1 h2 h3 h4 h5 h6 hr html i iframe img ins input kbd keygen label legend li link map mark menu menuitem meta meter nav object ol optgroup option output p param pre progress q s samp script section select small source span strong style sub summary sup table td th tr textarea time title track u ul var video]>
selfClosingTags = <[area base br col command embed hr img input keygen link meta param source track wbr]>
customTags = <[root text]>

events = <[click]>

window.DOM = {}

anchorNb = 0

class Node

  (@name, @attrs = {}, ...@origChildren) ->
    @_type = 'Node'
    throw "Unknown Tag: #{name}" if @name not in tags and @name not in customTags

    if @name in customTags
      switch @name
        | \text =>
          @text = @attrs
          @Resolve = -> @text

    if @attrs? and (typeof! @attrs isnt \Object or @attrs._promise? or @attrs.then? or @attrs._type is \Node)
      @origChildren.unshift @attrs
      @attrs = {}

    @attrs.anchor = anchorNb++

    @origChildren = @_Flatten @origChildren
    @currentChildren = @origChildren


  # Change every child into a Renderable Node
  Resolve: ->
    d = q.defer!
    @currentChildren = @origChildren
    async.mapSeries @currentChildren, @~_ResolveType, (err, childs) ~>
      return d.reject err if err?

      childs = @_Flatten childs

      @children = childs
      async.mapSeries childs, (item, done) ~>
        promise = item.Resolve!

        if promise.then?
          promise.then -> done null it
          promise.catch done
        else
          done null promise

      ,(err, childs) ~>
        return d.reject err if err?

        childs = childs |> map ~> it.parent = @
        d.resolve @

    return d.promise

  Render: ->
    @node = "<#{@name}#{@_MakeAttrStr!}"

    if @name in selfClosingTags
      return @_ManageSelfClosing!

    @node += '>'

    @_RenderChildren @node

  SetEvents: ->
    if @name isnt \root and any (in events), keys @attrs
      node = document.querySelector("#{@name}[anchor='#{@attrs.anchor}']")

      node.onclick = @attrs.click

    if @children
      @children |> map (.SetEvents!)

  Make: ->
    d = q.defer!
    anchor = ''
    if @name is \root
      anchor = document.querySelector("body")
    else
      anchor = document.querySelector("#{@name}[anchor='#{@attrs.anchor}']")

    dom = @Resolve!
    dom
      .then ->
        html = it.Render!
        anchor.outerHTML = html
        it.SetEvents!
        d.resolve html

      .catch -> d.reject it

    return d.promise

  _RenderChildren: ->
    if @name is \text
      return @node = @text
    if @name is \root
      return @node = @children |> map (.Render!) |> fold (+), ''

    @node += @children |> map (.Render!) |> fold (+), ''
    @node += "</#{@name}>"

    @node

  _Flatten: (array) ->
    newArray = []

    for item in array
      if typeof! item is \Array
        newArray = newArray.concat item
      else
        newArray.push item

    newArray

  _MakeAttrStr: ->
    return '' if not @attrs?
    res = ''
    for k, v of @attrs when k isnt \click
      res += " #k=\"#v\""
    res

  _ManageSelfClosing: ->
    if @origChildren.length
      throw "Self closing tags cannot have children: #{@name}"

    @node += ' />'

  _ResolveType: (child, done) ->
    switch
      | typeof! child is \String      => @_String child, done
      | typeof! child is \Array       => @_Array child, done
      | child.then?                   => @_Promise child, done
      | child._promise?               => @_ResourcePromise child, done
      | child.Then?                   => @_ResourceInst child, done
      | child._type is \Node          => @_Node child, done
      | child.Render?                 => @_View child, done
      | _                             => @_String '' + child, done

  _String:    (text, done)      -> done null new Node \text text
  _Node:      (node, done)      -> done null node
  _Array:     (array, done)     -> async.mapSeries array, @~_ResolveType, done

  _View:      (view, done)      ->
    view.Render (err, res)~>
      return done err if err?

      @_ResolveType res, done

  _Promise: (promise, done) ->
    promise
      .then  -> done null, it
      .catch -> done it

  _ResourceInst: (resourceInst, done) ->
    throw "No Render() on #{resourceInst._type}. Attach view first" if not resourceInst.Render?
    resourceInst.Render done

  _ResourcePromise: (resourcePromise, done) ->
    resourcePromise
      .Then  ~>
        @_ResolveType it, done

      .Catch -> done it

  GetElement: ->
    document.querySelector("#{@name}[anchor='#{@attrs.anchor}']")

tags |> each (tag) ->
  DOM[tag] = (...args) ->  new (Node.bind.apply Node, [Node, tag].concat args)

DOM.root = (...args) -> new (Node.bind.apply Node, [Node, \root].concat args)

window.Node = Node
