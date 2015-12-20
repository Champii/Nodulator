require! {
  underscore: _
  q
  async
}

tags = <[a abbr address area article aside audio b base bdo blockquote body br button canvas caption cite code col colgroup datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form head header h1 h2 h3 h4 h5 h6 hr html i iframe img ins input kbd keygen label legend li link map mark menu menuitem meta meter nav object ol optgroup option output p param pre progress q s samp script section select small source span strong style sub summary sup table td th tr textarea time title track u ul var video]>
selfClosingTags = <[area base br col command embed hr img input keygen link meta param source track wbr]>
customTags = <[root text func]>

events = <[click change]>

window.DOM = {}
class Node

  @anchorNb = 0

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

    @attrs.anchor = Node.anchorNb++

    @origChildren = @_Flatten @origChildren

  # Change every child into a Renderable Node
  Resolve: ->
    d = q.defer!
    async.mapSeries @origChildren, @~_ResolveType, (err, childs) ~>
      return d.reject err if err?

      childs = @_Flatten childs
      childs = childs |> map ~> it.parent = @; it

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

        d.resolve @

    return d.promise

  Render: (parent) ->
    if (anchor = @GetElement!)
      anchor.outerHTML = ''

    if not parent
      anchor = document.querySelector("body")
    else
      anchor = parent.GetElement!

    if @name is \text
      return anchor.innerHTML += @text

    @node = "<#{@name}#{@_MakeAttrStr!}"

    if @name in selfClosingTags and @origChildren.length
      throw "Self closing tags cannot have children: #{@name}"
    else if @name in selfClosingTags
      @node += ' />'
      return anchor.innerHTML += @node
    else
      @node += '>'

    anchor.innerHTML += @node

    if @children?
      @children |> map ~>
        if typeof! it is \Array
          it |> map ~> it.Render @
        else
          it.Render? @

  SetEvents: ->
    if @name isnt \root and any (in events), keys @attrs
      node = @GetElement!

      if @attrs.click?
        node.onclick = ~>
          @attrs.click ...
      if @attrs.change?
        node.onkeyup = ~>
          @attrs.change ...

    if typeof! @attrs?.value is \Function
      node.value = @attrs.value!

    if @children?
      @children |> map (.SetEvents?!)

  Make: ->
    d = q.defer!
    dom = @Resolve!
    dom
      .then ~>
        d.resolve it.Render @parent
        it.SetEvents!

      .catch -> d.reject it

    return d.promise

  GetElement: ->
    if @name is \text and @parent?
      return document.querySelector("#{@name}[anchor='#{@attrs.anchor}']")
    # else
    document.querySelector("#{@name}[anchor='#{@attrs.anchor}']")

  Empty: (@origChildren = []) ->

  AddChild: ->
    @origChildren.push it
    @

  _Flatten: (array) ->
    newArray = []

    for item in array
      if typeof! item is \Array
        newArray = newArray.concat item
      else
        newArray.push item

    newArray |> filter -> it?

  _MakeAttrStr: ->
    return '' if not @attrs?
    res = ''
    for k, v of @attrs when k isnt \click
      res += " #k=\"#v\""
    res

  _ResolveType: (child, done) ->
    # console.log 'Child', child
    switch
      | child is undefined            => @_String '', done
      | typeof! child is \String      => @_String child, done
      | typeof! child is \Array       => @_Array child, done
      | child.then?                   => @_Promise child, done
      | child._promise?               => @_ResourcePromise child, done
      | child.Then?                   => @_ResourceInst child, done
      | child._type is \Node          => @_Node child, done
      | child.Render?                 => @_View child, done
      | typeof! child is \Function    => @_Function child, done
      | _                             => @_String '' + child, done

  _String:    (text, done)            -> done null new Node \text text
  _Node:      (node, done)            -> done null node
  _Array:     (array, done)           -> async.mapSeries array, @~_ResolveType, done
  _Function:  (f, done)               ->
    done null new WatchableNode f, @

  _View:      (view, done) ->
    view.Render (err, res) ~>
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

class WatchableNode extends Node
  (@func, @parent) ->
    @name = \func
    @attrs = anchor: Node.anchorNb++

    @children = []
    first = true
    N.Watch ~>
      res = @func!
      if first
        return first := false

      @Rerender!catch console~error

  Resolve: ->
    d = q.defer!
    @_ResolveType @func!, (err, child) ~>
      return d.reject err if err?

      if typeof! child isnt \Array
        child = [child]

      @children = child
      async.mapSeries @children, (item, done) ~>
        promise = item.Resolve!

        if promise.then?
          promise.then -> done null it
          promise.catch done
        else
          done null promise

      ,(err, childs) ~>
        return d.reject err if err?

        d.resolve @

    return d.promise

  Rerender: ->
    d = q.defer!

    @Resolve!
      .then ~>
        if (anchor = @GetElement!)
          anchor.innerHTML = ''

        it.Render @parent
        it.SetEvents!
        d.resolve it
      .catch ->
        d.reject it

    return d.promise

tags |> each (tag) ->
  DOM[tag] = (...args) ->  new (Node.bind.apply Node, [Node, tag].concat args)

DOM.root = (...args) -> new (Node.bind.apply Node, [Node, \root].concat args)

DOM.map_ = DOM.map
DOM.head_ = DOM.head
delete DOM.map
delete DOM.head

# (intersection tags, keys window) |> each ->
#   if it isnt \div and it isnt \span
#     DOM[it + \_] = DOM[it]
#     delete DOM[it]
  # else
  #   window[it + \_] = window[it]
  #   delete window[it]
window import DOM

# window.Node = Node
