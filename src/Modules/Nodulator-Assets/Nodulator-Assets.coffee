_ = require 'underscore'
fs = require 'fs'
path = require 'path'
jade = require 'jade'
cookieParser = require 'cookie-parser'
coffeeMiddleware = require 'coffee-middleware'
livescriptMiddleware = require 'livescript-middleware'

module.exports = (Nodulator) ->

  class Assets

    list: {}
    views: {}
    extendedRun: []
    extendedRender: []
    compiled: false
    engine: jade
    name: 'Assets'


    constructor: ->

      Nodulator.ExtendDefaultConfig
        assets:
          app:
            path: '/client'
            js: ['/client/public/js/', '/client/']
            css: ['/client/public/css/']
        viewRoot: 'client'
        engine: 'jade' #FIXME: no other possible engine

      Nodulator.Config() if not Nodulator.config?

      for site, obj of Nodulator.config.assets
        o = {}
        o["/js/#{site}.js"] = Nodulator.config.assets[site].js
        o["/css/#{site}.css"] = Nodulator.config.assets[site].css
        @AddFolders o

      thus = this

      # To be called last
      Nodulator.Run = ->

        process() for process in thus.extendedRun

        # FIXME: ugly fix for favicon
        @app.get '/favicon.ico', (req, res) =>
          res.status(200).end()

        @app.get '*', (req, res) =>
          @Render req, res

      Nodulator.Render = (req, res) ->

        for process in thus.extendedRender
          if not process req, res
            return

        res.render 'index'

      Nodulator.ExtendBeforeRender = (process) =>
        @extendedRender.unshift process

      Nodulator.ExtendAfterRender = (process) =>
        @extendedRender.push process

      Nodulator.ExtendBeforeRun = (process) =>
        @extendedRun.unshift process

      Nodulator.ExtendAfterRun = (process) =>
        @extendedRun.push process

      Nodulator.ExtendBeforeRun =>
        @_Serve()

    _GetFiles: (name, dirs, rec = false) ->
      for dir in dirs when dir?

        if dir[dir.length - 1] isnt '/'
          dir += '/'

        entries = fs.readdirSync path.resolve Nodulator.appRoot, '.' + dir

        files = _(entries).filter (entry) =>
          fs.statSync(Nodulator.appRoot + dir + entry).isFile() and
            (entry.match(/\.coffee$/g) or entry.match(/\.js$/g) or entry.match(/\.css$/g))

        if rec
          folders = _(entries).filter (entry) =>
            fs.statSync(Nodulator.appRoot + dir + entry).isDirectory() and
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
      Nodulator.app.use cookieParser 'nodulator'
      #
      # Nodulator.app.use livescriptMiddleware
      #   src: path.resolve Nodulator.appRoot, '.'
      #   prefix: 'js'
      #   force: true
      #   bare: true

      Nodulator.app.use coffeeMiddleware
        src: path.resolve Nodulator.appRoot, '.'
        prefix: 'js'
        bare: true
        force: true

      Nodulator.app.use require('connect-cachify').setup @list,
        root: path.join Nodulator.appRoot, '.'
        production: false

      Nodulator.app.use Nodulator.express.static Nodulator.appRoot

      Nodulator.app.set 'views', path.resolve Nodulator.appRoot, Nodulator.config.viewRoot
      Nodulator.app.engine '.' + Nodulator.config.engine, jade.__express
      Nodulator.app.set 'view engine', Nodulator.config.engine

      Nodulator.app.use (req, res, next) =>

        res.locals.nodulator = (site = 'app') =>
          jcompile = {}
          if Nodulator.nangulator?
            jcompile = _(jcompile).extend Nodulator.nangulator.Compile()

          @compiled = {}
          for name, list of @list
            site_ = name.split('/')[2].split('.')[0]
            @compiled[site_] = jcompile[site_]() if not @compiled[site_]?

          comp = @compiled[site]
          comp += res.locals.cachify_css "/css/#{site}.css"
          comp += res.locals.cachify_js "/js/#{site}.js"

          if Nodulator.AccountResource?
            comp += Nodulator.AccountResource._AccountResource._InjectUser req

          comp

        next()

    AddView: (view, site = 'app') ->
      @views[site] = '' if not @views[site]?
      @views[site] += view

  Nodulator.assets = new Assets
