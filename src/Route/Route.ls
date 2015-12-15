require! \prelude-ls : {each, unchars}
_ = require 'underscore'
N = null
Request = require './Request'
require! {\../Helpers/Debug}
express = require \express
Client = require '../../test/common/client'
http = require 'http'
body-parser = require \body-parser
express-session = require 'express-session'

debug = new Debug "N::Route", Debug.colors.purple

class Route

  basePath: '/api/'
  apiVersion: 1
  rname: ''

  (resource, @config) ->

    @resource = resource || @resource

    N := require '../..' if not N?

    if @resource
      if typeof(@resource) is 'function'
        @rname = @resource.lname
      else if typeof(@resource) is 'string'
        @rname = @resource
        @resource = undefined
        N.Config() if not N.config?
      else
        throw new Error 'Route needs a Resource (or at least a name)'

    @debug = new Debug "N::Route::#{@rname}", Debug.colors.purple

    N.Config!
    if N.consoleMode
      return

    if not N.app?
      N.Route._InitServer!

    @app = N.app

    @name = @rname + 's'

    if @rname[*-1] is 'y'
      @name = @rname[til @name.length - 2]*'' + 'ies'

    @Config()

  @_InitServer = ->
    N := require '../..' if not N?

    if N.app?
      debug.Log 'Server already started.'
      return

    N.express = express

    N.app = express!

    N.app.use bodyParser.urlencoded  extended: true

    N.app.use bodyParser.json  extended: true

    sessions =
      key: \N
      secret: \N
      resave: true
      saveUninitialized: true

    if N.config?.store?.type is \redis
      RedisStore = require(\connect-redis)(express-session)

      N.sessionStore = new RedisStore do
        host: N.config.store.host || \localhost

      sessions.store = N.sessionStore

    N.app.use express-session sessions

    debug.Log 'Creating server'

    N.server = http.createServer N.app

    N.client = new Client N.app


    N.server.listen N.config?.port || 3000

    N.bus.emit \listening

    debug.Log "Listening to 0.0.0.0: #{(N.config?.port || 3000)}"

  _WrapRequest: (fName, args) ->
    Req = new Request args
    try
      ret = @[fName] Req
      if ret?
        switch
          | ret._promise? =>
            ret
              .Then -> Req.Send it
              .Catch -> Req.SendError it
          | _         => Req.Send ret
      else if ret is null => Req.Send null
    catch e
      Req.SendError e

  _Add: (type, url, ...middle, done) ->
    if not done?
      done = url
      url = switch type
        | \all  => \*
        | _     => \/

    if not middle.length and typeof(url) is 'function'
      middle.push url
      url = switch type
        | \all  => \*
        | _     => \/

    @debug.Log "Declaring Route: #{type} => #{url} "

    if not @[type + url]?
      @[type + url] = done

      #FIXME: code clarity
      if middle.length
        middle.push (...args) ~>
          @debug.Log "Request on: #{type} => #{url} "
          @_WrapRequest type + url,  args
        @app.route(@basePath + @apiVersion + '/' + @name + url)[type].apply @app.route(@basePath + @apiVersion + '/' + @name + url), middle
      else
        @app.route(@basePath + @apiVersion + '/' + @name + url)[type] (...args) ~>
          @debug.Log "Request on: #{type} => #{url} "
          @_WrapRequest type + url,  args

    else
      @[type + url] = done

  Config: ->

  @Extend = ->
    class ExtendedRoute extends @

_set = (verb) ~>
  Route::[verb] = (...args) ->
    args.unshift verb[0].toLowerCase() + verb[1 til verb.length]*''
    @_Add.apply @, args

each _set, <[ All Post Get Put Delete ]>

class Collection extends Route

  Config: ->
    super()
    @All    \/:id* ~> it.SetInstance @resource.Fetch +it.params.id
    @Get           ~> @resource.List it.query
    @Post          ~> @resource.Create it.body
    @Get    \/:id  ~> it.instance
    @Put    \/:id  ~> it.instance.Set it.body
    @Delete \/:id  ~> it.instance.Delete!

class RPC extends Route

  Config: ->
    super()
    @Post \/list        ~> @resource.List   it.body
    @Post \/create      ~> @resource.Create it.body
    @Post \/fetch       ~> @resource.Fetch  it.body
    @Post \/set/:id     ~> @resource.Fetch  +it.params.id .Set it.body
    @Post \/delete/:id  ~> @resource.Delete +it.params.id

Route.RPC = RPC
Route.Collection = Collection
module.exports = Route
