require! {
  \../.. : N
  q
  async
}

global import require \prelude-ls

makeAttrStr = ->
  return '' if not it?
  res = ''
  for k, v of it
    res += " #k=\"#v\""
  res

resolveChildren = (children, done) ->
  async.mapSeries children, (item, done) ->
    if item._promise?
      item
        .Then -> done null, it
        .Catch done
    else if typeof! item is \Object
      item
        .then -> done null, it
        .catch done
    else
      done null item
  , done

createElement = (name, attrs, ...children = [], done) ->
  throw "Unknown Tag: #{name}" if name not in tags

  async = false

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


  selfClosing = false
  if name in selfClosingTags
    selfClosing = true

  if selfClosing and children.length
    throw "Self closing tags cannot have children: #{name}"

  for child in children
    if child._promise? or typeof! child is \Object
      async := true

  node = "<#name#{makeAttrStr attrs}"

  if selfClosing
    node += ' />'
  else
    node += '>'

  if selfClosing
    return node

  if async is true
    d = q.defer!
    resolveChildren children, (err, res) ->
      return d.reject err if err?

      for child in res
        if typeof! child is \Array
          for grandchild in child
            node += grandchild
        else
        # console.log 'Resolved' child
          node += child

      node += "</#name>"

      d.resolve node

    return d.promise

  for child in children
    node += child

  node + "</#name>"

tags = <[a abbr address area article aside audio b base bdo blockquote body br button canvas caption cite code col colgroup datalist dd del details dfn dialog div dl dt em embed fieldset figcaption figure footer form head header h1 h2 h3 h4 h5 h6 hr html i iframe img ins input kbd keygen label legend li link map mark menu menuitem meta meter nav object ol optgroup option output p param pre progress q s samp script section select small source span strong style sub summary sup table td th tr textarea time title track u ul var video]>
selfClosingTags = <[area base br col command embed hr img input keygen link meta param source track wbr]>

DOM = {}

tags |> each (tag) ->
  DOM[tag] = -> createElement.apply this, [tag].concat Array::slice.call(arguments);

class View

  (@resource) ->
    # if not @resource.routes?
    #   @resource.AttachRoute N.Route.Collection

    # N.app.get \/ (req, res) -> res.status(200).send('hello')

    @resource.Render = ~> @.__proto__.constructor.Render.call @resource

    @resource::Render =  @Render


View.DOM = DOM

module.exports = View
