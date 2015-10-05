_ = require 'underscore'
fs = require 'fs'
path = require 'path'
jade = require 'jade'
cookieParser = require 'cookie-parser'
coffeeMiddleware = require 'coffee-middleware'
livescriptMiddleware = require 'livescript-middleware'

module.exports = (N) ->

  class Assets

    list: {}
    views: {}
    extendedRun: []
    extendedRender: []
    compiled: false
    engine: jade
    name: 'Assets'


    constructor: ->

      N.ExtendDefaultConfig
        assets:
          app:
            path: '/client'
            js: ['/client/public/js/', '/client/']
            css: ['/client/public/css/']
        viewRoot: 'client'
        engine: 'jade' #FIXME: no other possible engine

      N.Config() if not N.config?

      for site, obj of N.config.assets
        o = {}
        o["/js/#{site}.js"] = N.config.assets[site].js
        o["/css/#{site}.css"] = N.config.assets[site].css
        @AddFolders o

      thus = this

      # To be called last
      N.Run = ->

        process() for process in thus.extendedRun

        # FIXME: ugly fix for favicon
        @app.get '/favicon.ico', (req, res) =>
          res.status(200).end()

        @app.get '*', (req, res) =>
          @Render req, res

      N.Render = (req, res) ->

        for process in thus.extendedRender
          if not process req, res
            return

        res.render 'index'

      N.ExtendBeforeRender = (process) =>
        @extendedRender.unshift process

      N.ExtendAfterRender = (process) =>
        @extendedRender.push process

      N.ExtendBeforeRun = (process) =>
        @extendedRun.unshift process

      N.ExtendAfterRun = (process) =>
        @extendedRun.push process

      N.ExtendBeforeRun =>
        @_Serve()

    _GetFiles: (name, dirs, rec = false) ->
      for dir in dirs when dir?

        if dir[dir.length - 1] isnt '/'
          dir += '/'

        entries = fs.readdirSync path.resolve N.appRoot, '.' + dir

        files = _(entries).filter (entry) =>
          fs.statSync(N.appRoot + dir + entry).isFile() and
            (entry.match(/\.coffee$/g) or entry.match(/\.js$/g) or entry.match(/\.css$/g))

        if rec
          folders = _(entries).filter (entry) =>
            fs.statSync(N.appRoot + dir + entry).isDirectory() and
              not entry.match(/^\./g)
          folders = _(folders).map (folder) =>
            dir + folder

          @_GetFiles name, folders, true

        files = _(files).map (file) =>
          if file.match(/\.coffee$/g)
            dir + file.replace(/\.coffee/g, '.js')
          else if file.match(/\.js$/g) or file.match(/\.css$/g)
            dir + file

        if not @list[name]
          @list[name] = files
        else
          @list[name] = @list[name].concat files

    AddFoldersRec: (list) ->
      for name, dirs of list
        @_GetFiles name, dirs, true

    AddFolders: (list) ->
      for name, dirs of list
        @_GetFiles name, dirs

    _Serve: ->
      N.app.use cookieParser 'nodulator'
      #
      # N.app.use livescriptMiddleware
      #   src: path.resolve N.appRoot, '.'
      #   prefix: 'js'
      #   force: true
      #   bare: true

      N.app.use coffeeMiddleware
        src: path.resolve N.appRoot, '.'
        prefix: 'js'
        bare: true
        force: true

      N.app.use require('connect-cachify').setup @list,
        root: path.join N.appRoot, '.'
        production: false

      N.app.use N.express.static N.appRoot

      N.app.set 'views', path.resolve N.appRoot, N.config.viewRoot
      N.app.engine '.' + N.config.engine, jade.__express
      N.app.set 'view engine', N.config.engine

      N.app.use (req, res, next) =>

        res.locals.nodulator = (site = 'app') =>
          jcompile = {}
          if N.nangulator?
            jcompile = _(jcompile).extend N.nangulator.Compile()

          @compiled = {}
          for name, list of @list
            site_ = name.split('/')[2].split('.')[0]
            @compiled[site_] = jcompile[site_]() if not @compiled[site_]?

          comp = @compiled[site]
          comp += res.locals.cachify_css "/css/#{site}.css"
          comp += res.locals.cachify_js "/js/#{site}.js"

          if N.AccountResource?
            comp += N.AccountResource._AccountResource._InjectUser req

          comp

        next()

    AddView: (view, site = 'app') ->
      @views[site] = '' if not @views[site]?
      @views[site] += view

  N.assets = new Assets
