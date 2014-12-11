_ = require 'underscore'
fs = require 'fs'
path = require 'path'
http = require 'http'
jade = require 'jade'
express = require 'express'
bodyParser = require 'body-parser'
cookieParser = require 'cookie-parser'
coffeeMiddleware = require 'coffee-middleware'

class Modulator

  app: null
  express: null
  server: null
  resources: {}
  directives: {}
  routes: {}
  config: null
  table: null
  assets: {}

  constructor: ->

    @appRoot = path.resolve '.'

    @_MakeAssetsList()

    @express = express

    @app = @express()

    @app.use bodyParser.urlencoded
      extended: true

    @app.use bodyParser.json
      extended: true

    @app.use cookieParser 'modulator'

    @app.use coffeeMiddleware
      src: path.resolve @appRoot, '.'
      prefix: 'js'
      bare: true
      force: true

    @app.use require('connect-cachify').setup @assets,
      root: path.join @appRoot, '.'
      production: false

    @app.use @express.static path.resolve @appRoot, 'client/public'

    @app.use do =>
      compiled = ''
      files = fs.readdirSync path.resolve(@appRoot, 'client/views')

      j = ''
      for file in files
        f = file.split('.')[0]
        j += '
          script#' + f + '-tpl(type="text/ng-template")\n
            include ' + f + '\n'

      j += '
        script(src="/socket.io/socket.io.js")\n'
      j += '
        script.\n
          var __user = !{JSON.stringify(user)};\n'

      compiled = jade.compile j,
        filename: path.resolve @appRoot, 'client/views'

      return (req, res, next) ->

        res.locals.modulator = ->
          compiled()

        next()

    @app.set 'views', path.resolve @appRoot, 'client'
    @app.engine '.jade', jade.__express
    @app.set 'view engine', 'jade'


    @app.get '/favicon.ico', (req, res) ->
      res.status(200).end()

    @app.get '*', (req, res) ->

      res.render 'index',
        user: {id: req.userId}


    @server = http.createServer @app

    @server.listen 3000

    @db = require('./connectors/sql')

  _MakeAssetsList: ->
    exp =
      "/js/app.js": ['/client/services/', '/client/directives/', '/client/controllers/', '/client/public/js/']
      "/css/app.css": ['/client/public/css/']

    for name, dirs of exp
      for dir in dirs
        files = fs.readdirSync path.resolve @appRoot, '.' + dir
        files = _(files).filter (file) => fs.statSync(@appRoot + dir + file).isFile()
        files = _(files).map (file) => dir + file.replace(/\.coffee/g, '.js')

        if not @assets[name]
          @assets[name] = files
        else
          @assets[name] = @assets[name].concat files

  Directive: (name) ->

  Resource: (name, routes, config, _parent) ->

    name = name.toLowerCase()
    if name is 'user'
      throw new Error 'Resource name \'user\' is reserved'

    if @resources[name]?
      return @resources[name]

    if routes? and not routes.prototype
      config = routes
      routes = null

    @Config() if !(@config?) # config of Modulator instance

    if not routes? or routes.prototype not instanceof @Route
      routes = @Route

    if _parent?
      @resources[name] = resource = _parent
      @resources[name]._PrepareResource @table(name + 's'), config, @app, routes, name
    else
      table = null
      if not config? or (config? and not config.abstract)
        table = @table(name + 's')

      @resources[name] = resource =
        require('./Resource')(table, config, @app, routes, name)

    resource

  Config: (@config) ->
    @config = @_DefaultConfig() if !(@config?)

    @table = @db(@config).table

  _DefaultConfig: ->
    dbType: 'SqlMem'

  Route: require('./Route')

  Reset: (done) ->
    @server.close()
    @resources = {}
    @config = null
    @table = null

    @app = express()

    @app.use bodyParser.urlencoded
      extended: true

    @app.use bodyParser.json
      extended: true

    @server = http.createServer @app

    @server.listen 3000

    @db._reset()
    @db = require('./connectors/sql')

    done() if done?

  ListEndpoints: (done) ->
    endpoints = []
    for endpoint in @app._router.stack
      if endpoint.route?
        res = {}
        res[endpoint.route.path] = key for key of endpoint.route.methods
        endpoints.push res
    done(endpoints) if done?

module.exports = new Modulator
