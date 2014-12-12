_ = require 'underscore'
fs = require 'fs'
path = require 'path'
jade = require 'jade'
express = require 'express'
cookieParser = require 'cookie-parser'
coffeeMiddleware = require 'coffee-middleware'

class Assets

  list: {}
  compiled: ''

  constructor: (@app, @appRoot, @viewsRoot) ->

    @MakeAssetsList()

    @InjectViews()

    @Serve()

  MakeAssetsList: ->
    exp =
      '/js/app_head.js': ['/client/public/js/', '/client/', '/client/public/js/modulator-angular/base/', '/client/public/js/modulator-angular/']
      '/js/app_body.js': ['/client/services/', '/client/directives/', '/client/controllers/']
      '/css/app.css': ['/client/public/css/']

    for name, dirs of exp
      for dir in dirs
        files = fs.readdirSync path.resolve @appRoot, '.' + dir

        files = _(files).filter (file) =>
          fs.statSync(@appRoot + dir + file).isFile() and
            (file.match(/\.coffee$/g) or file.match(/\.js$/g))

        files = _(files).map (file) =>
          if file.match(/\.coffee$/g)
            dir + file.replace(/\.coffee/g, '.js')
          else if file.match(/\.js$/g)
            dir + file

        if not @list[name]
          @list[name] = files
        else
          @list[name] = @list[name].concat files

  CompileViews: ->
    res = ''
    files = fs.readdirSync path.resolve(@appRoot, @viewsRoot)

    j = ''
    for file in files
      f = file.split('.')[0]
      j += '
        script#' + f + '-tpl(type="text/ng-template")\n
          include views/' + f + '\n'

    j += '
      script(src="/socket.io/socket.io.js")\n'
    j += '
      script.\n
        var __user = !{JSON.stringify(user) || \'{}\'};\n'

    res = jade.compile j,
      filename: path.resolve @appRoot, @viewsRoot

    @compiled = res()

  InjectViews: ->
    @app.use (req, res, next) =>
      @CompileViews()
      res.locals.modulator = => @compiled
      next()

  Serve: ->
    @app.use cookieParser 'modulator'

    @app.use coffeeMiddleware
      src: path.resolve @appRoot, '.'
      prefix: 'js'
      bare: true
      force: true

    @app.use require('connect-cachify').setup @list,
      root: path.join @appRoot, '.'
      production: false

    @app.use express.static @appRoot

    @app.set 'views', path.resolve @appRoot, 'client'
    @app.engine '.jade', jade.__express
    @app.set 'view engine', 'jade'

module.exports = Assets
