require! {
  underscore: _
  q
  async
}

makeAttrStr = ->
  return '' if not it?
  res = ''
  for k, v of it when k isnt \click
    res += " #k=\"#v\""
  res

resolveChildren = (children, done) ->
  async.mapSeries children, (item, done) ->
    if item._promise?
      item
        .Then -> done null, it
        .Catch -> done it
    else if item.then?
      item
        .then -> done null, it
        .catch -> done it
    else
      done null item
  , done

prepareArgs = (name, attrs, children) ->
  throw "Unknown Tag: #{name}" if name not in tags

  if attrs? and (typeof! attrs isnt \Object or attrs._promise? or attrs.then?)
    children.unshift attrs
    attrs := {}

  newChildren = []

  for child in children
    if typeof! child is \Array
      newChildren = newChildren.concat child
    else
      newChildren.push child

  children = newChildren

  {name, attrs, children}

manageSelfClosing = (name, node, children) ->

  if children.length
    throw "Self closing tags cannot have children: #{name}"

  return node + ' />'

isAsync = (children) ->
  for child in children
    if child._promise? or typeof! child is \Function or child.then?
      return true

  false

asyncMode = (name, node, children) ->
  d = q.defer!
  resolveChildren children, (err, res) ->
    return d.reject err if err?

    async.eachSeries res, (child, done) ->
      if typeof! child is \Array
        for grandchild in child
          if grandchild.Render?
            grandchild = grandchild.Render!
          node += grandchild
      else
        if child.Render?
          child = child.Render!
        if child.then?
          child.then ->
            node += it
            done!
          child.catch ->
            done it
          return
        node += child

      done!
    , (err, results) ->
      return d.reject err if err?
      node += "</#name>"

      d.resolve node

  return d.promise

createElement = (name, attrs, ...children) ->
  {name, attrs, children} = prepareArgs name, attrs, children

  node = "<#name#{makeAttrStr attrs}"

  if name in selfClosingTags
    return manageSelfClosing name, node, children

  node += '>'

  if isAsync children
    return asyncMode name, node, children

  for child in children
    node += child

  node + "</#name>"

tags = <[a abbr address area article aside audio b base bdo blockquote body br button canvas caption cite code col colgroup datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form head header h1 h2 h3 h4 h5 h6 hr html i iframe img ins input kbd keygen label legend li link map mark menu menuitem meta meter nav object ol optgroup option output p param pre progress q s samp script section select small source span strong style sub summary sup table td th tr textarea time title track u ul var video]>
selfClosingTags = <[area base br col command embed hr img input keygen link meta param source track wbr]>

DOM = {}

tags |> each (tag) ->
  DOM[tag] = -> createElement.apply this, [tag].concat Array::slice.call(arguments);

class View

  @_type = 'View'

  (@resource) ->
    @resource.Render = ~> @.__proto__.constructor.Render.call @resource
    @resource::Render = @Render

View.DOM = DOM

N.View = View

N.Render = (func) ->
  # N.View.ActualRender = (done) ~>
  body = document.getElementsByTagName('body').0
  #Beta
  #body.innerHTML = ''

  dom = func!
  if dom.Render?
    dom = dom.Render!
  if typeof! dom is \Object and dom.then?
    dom.then ->
      body.innerHTML += it
    dom.catch console~error
    return

  body.innerHTML += dom
