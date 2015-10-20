_ = require 'underscore'
fs = require 'fs'
path = require 'path'
jade = require 'jade'
cookieParser = require 'cookie-parser'
coffeeMiddleware = require 'coffee-middleware'
livescriptMiddleware = require 'livescript-middleware'
compressor = require 'node-minify'
minify = require 'express-minify'
grunt = require 'grunt'

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
            css: ['/client/public/public/css/']
        viewRoot: 'client'
        engine: 'jade' #FIXME: no other possible engine
        minified: false

      N.Config() if not N.config?

      for site, obj of N.config.assets
        o = {}
        o["#{N.config.assets[site].path}/public/#{site}.min.js"] = N.config.assets[site].js
        o["#{N.config.assets[site].path}/public/#{site}.min.css"] = N.config.assets[site].css
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

    _InitGrunt: ->
      grunt.task.init = ->

      coffee = {}
      for name, files of @list
        if name.split('/')[name.split('/').length - 1].split('.')[2] is 'js'
          name_ = name[1..].replace /\.min/g, '.coffee'
          coffee[name_] = _(files).filter (item) -> item.split('.')[1] is 'coffee'
          coffee[name_] = _(coffee[name_]).map (item) -> item[1..]

      minifiedJs = {}
      for name, files of @list
        if name.split('/')[name.split('/').length - 1].split('.')[2] is 'js'
          coffeeName = name[1..].replace /\.min/g, '.coffee'
          name_ = name[1..]
          minifiedJs[name_] = _(files).filter (item) -> item.split('.')[item.split('.').length - 1] is 'js'
          minifiedJs[name_] = _(minifiedJs[name_]).map (item) -> item[1..]
          minifiedJs[name_].push coffeeName

      minifiedCss = {}
      for name, files of @list
        if name.split('/')[name.split('/').length - 1].split('.')[2] is 'css'
          name_ = name[1..]
          minifiedCss[name_] = _(files).filter (item) -> item.split('.')[item.split('.').length - 1] is 'css'
          minifiedCss[name_] = _(minifiedCss[name_]).map (item) -> item[1..]

      grunt.initConfig
        coffee:
          compile:
            options:
              join: true
            #   bare: true
            files: coffee
        uglify:
          assets:
            options:
              beautify: true
              mangle: false
            files: minifiedJs
        cssmin:
          assets:
            files: minifiedCss

      grunt.loadNpmTasks('grunt-contrib-coffee');
      grunt.loadNpmTasks('grunt-contrib-uglify');
      grunt.loadNpmTasks('grunt-contrib-cssmin');
      grunt.loadNpmTasks('grunt-ngmin');

    _RunGrunt: ->
      grunt.tasks ['coffee', 'uglify', 'cssmin'], {}, ->
        grunt.log.ok('Done running tasks.');

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
            fs.statSync(N.appRoot + dir + entry).isDirectory() and not entry.match(/^\./g)
          folders = _(folders).map (folder) =>
            dir + folder

          @_GetFiles name, folders, true

        files = _(files).map (file) =>
          if file.match(/\.coffee$/g)
            dir + file
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

      if N.config.minified
        @_InitGrunt()
        @_RunGrunt()

      @compiled = {}
      Compile = (site) =>
        jcompile = {}
        if N.nangulator?
          jcompile = _(jcompile).extend N.nangulator.Compile()

        for name, list of @list
          site_ = name.split('/')[name.split('/').length - 1].split('.')[0]
          @compiled[site_] = jcompile[site_]() if not @compiled[site_]?

        @compiled[site]

      url_to_paths = {}
      if N.config.minified
        # for site, files of @list
        #   site_ = site.split('/')[site.split('/').length - 1].split('.')[0]
        #   files_ = _(files).map (item) -> N.appRoot + item
        #   compressor.minify
        #     type: 'uglifyjs'
        #     fileIn: files_
        #     fileOut: "#{N.config.assets[site_].path}/public/js/#{site_}.js"
        for site, config of N.config.assets

          Compile site

      if not N.config.minified

        for site, paths of @list
          if site.split('/')[site.split('/').length - 1].split('.')[2] is 'js'

            @list[site] = _(paths).map (item) ->
              if item.split('.')[1] is 'coffee'
                item.replace /\.coffee/g, '.js'
              else
                item


        N.app.use coffeeMiddleware
          src: path.resolve N.appRoot, '.'
          prefix: 'coffee'
          bare: true
          force: true

      # N.app.use minify()
      N.app.use require('connect-cachify').setup @list,
        # root: path.join N.appRoot, '.'
        root: path.resolve N.appRoot
        # url_to_paths: url_to_paths
        production: N.config.minified
        # debug: true



      N.app.use cookieParser 'nodulator'

      N.app.use N.express.static N.appRoot

      N.app.set 'views', path.resolve N.appRoot, N.config.viewRoot
      N.app.engine '.' + N.config.engine, jade.__express
      N.app.set 'view engine', N.config.engine

      N.app.use (req, res, next) =>

        res.locals.nodulator = (site = 'app') =>
          comp = {}
          if not N.config.minified
            @compiled = {}
            comp = Compile site
          else
            comp = @compiled[site]

          comp += res.locals.cachify_js "#{N.config.assets[site].path}/public/#{site}.min.js"
          comp += res.locals.cachify_css "#{N.config.assets[site].path}/public/#{site}.min.css"

          if N.AccountResource?
            comp += N.AccountResource._AccountResource._InjectUser req

          comp

        next()

    AddView: (view, site = 'app') ->
      @views[site] = '' if not @views[site]?
      @views[site] += view

  N.assets = new Assets
