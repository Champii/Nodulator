_ = require 'underscore'
fs = require 'fs'
path = require 'path'
jade = require 'pug'
cookieParser = require 'cookie-parser'
coffeeMiddleware = require 'coffee-middleware'
livescriptMiddleware = require 'livescript-middleware'
grunt = require 'grunt'
path = require 'path'

NModule = require \../NModule

class NAssets extends NModule

  views: {}
  extendedRun: []
  extendedRender: []
  compiled: false
  engine: jade
  name: 'NAssets'

  defaultConfig:
    sites:
      root:
        path: './'
        mount: '/'
        public:
          '/img': '/'
          js: ['/']
          vendors: ['/']
          css: ['/']

    engine: 'pug' #FIXME: no other possible engine
    minified: false

  Init: ->
    @list = {}
    N.assets = @

    N.Route._InitServer!
    for site, obj of @config.sites
      @AddFoldersRec do
        "#{@config.sites[site].path}/#{site}.vendors_min.js" :  @config.sites[site].public?.vendors || [\/]
        "#{@config.sites[site].path}/#{site}.min.js" :  @config.sites[site].public?.js || [\/]
        "#{@config.sites[site].path}/#{site}.min.css" : @config.sites[site].public?.css || [\/]
      @AddFoldersRec do
        "#{@config.sites[site].path}/#{site}.min.js" :  @config.sites[site].public?.js || [\/]
        \ls
      @AddFoldersRec do
        "#{@config.sites[site].path}/#{site}.min.js" :  @config.sites[site].public?.js || [\/]
        \coffee

    thus = this

    # To be called last
    N.Run = ~>

      for process in thus.extendedRun
        process!

      # FIXME: ugly fix for favicon
      N.app.get '/favicon.ico', (req, res) ~>
        res.status(200).end()

      for site, conf of @config.sites
        let config = conf, site = site
          N.app.get config.mount || config.path || '/', (req, res) ~>
            N.Render config.path || config.mount || '/', req, res

      N.app.get '*', (req, res) ~>
        res.status 404 .send \404

    N.Render = (site, req, res) ->

      for process in thus.extendedRender
        if not process req, res
          return

      /*site = site[1 to]*''*/
      if site.length
        site += \/
      # console.log \SITE site
      res.render site + 'index'

    N.ExtendBeforeRender = (process) ~>
      @extendedRender.unshift process

    N.ExtendAfterRender = (process) ~>
      @extendedRender.push process

    N.ExtendBeforeRun = (process) ~>
      @extendedRun.unshift process

    N.ExtendAfterRun = (process) ~>
      @extendedRun.push process

    N.ExtendBeforeRun ~>
      @_Serve()


  PostConfig: ->
    N.Run!

  _InitGrunt: ->
    grunt.task.init = ->

    coffee = {}
    for name, files of @list
      if name.split('/')[name.split('/').length - 1].split('.')[2] is 'js'
        name_ = (name[1 to]*'').replace /\.min/g, '.coffee'
        coffee[name_] = _(files).filter (item) -> item.split('.')[1] is 'coffee'
        coffee[name_] = _(coffee[name_]).map (item) -> item[1 to]*''

    minifiedJs = {}
    for name, files of @list
      if name.split('/')[name.split('/').length - 1].split('.')[2] is 'js'
        /*coffeeName = name[1 to]*''.replace /\.min/g, '.coffee'*/
        /*console.log \ASDASD name[1 to]*'', coffeeName*/
        name_ = name[1 to]*''
        minifiedJs[name_] = _(files).filter (item) -> item.split('.')[item.split('.').length - 1] is 'js'
        minifiedJs[name_] = _(minifiedJs[name_]).map (item) -> item[1 to]*''
        /*minifiedJs[name_].push coffeeName*/

    minifiedCss = {}
    for name, files of @list
      if name.split('/')[name.split('/').length - 1].split('.')[2] is 'css'
        name_ = name[1 to]*''
        minifiedCss[name_] = _(files).filter (item) -> item.split('.')[item.split('.').length - 1] is 'css'
        minifiedCss[name_] = _(minifiedCss[name_]).map (item) -> item[1 to]*''

    gruntConf = {}

    coffeeConf =
      coffee:
        compile:
          options:
            join: true
          #   bare: true
          files: coffee

    uglifyConf =
      uglify:
        assets:
          options:
            # beautify: true
            mangle: false
          files: minifiedJs

    cssminConf =
      cssmin:
        assets:
          files: minifiedCss

    oldDir = process.cwd!
    process.chdir N.libRoot

    @tasks = {}

    @tasks.coffee = !!that if (flatten values @list |> filter (-> it.match /\.coffee/g)).length
    @tasks.cssmin = !!that if (flatten values @list |> filter (-> it.match /\.css/g)   ).length
    @tasks.uglify = !!that if (flatten values @list                                    ).length

    gruntConf import coffeeConf if @tasks.coffee
    gruntConf import cssminConf if @tasks.cssmin
    gruntConf import uglifyConf if @tasks.uglify

    grunt.initConfig gruntConf

    grunt.loadNpmTasks('grunt-contrib-coffee') if @tasks.coffee
    grunt.loadNpmTasks('grunt-contrib-uglify') if @tasks.uglify
    grunt.loadNpmTasks('grunt-contrib-cssmin') if @tasks.cssmin

    process.chdir oldDir

  _RunGrunt: ->
    if keys @tasks .length
      grunt.tasks keys(@tasks), {force: true}, ->
        grunt.log.ok('Done running tasks.');

  _GetFiles: (name, dirs, ext, rec = false, before = false) ->
    _site = (name.split \/ |> reverse |> (.0)).split \. |> reverse |> (.2)
    /*console.log '_SITE' dirs, _site*/

    for dir in dirs when dir?
      # console.log 'GETFILES' dir, ext
      dir2 = dir
      basePath = path.resolve N.appRoot, @config.sites[_site].path
      if dir2 is \/
        dir2 = basePath
      else if dir2.0 isnt \/
        dir2 = path.resolve @config.sites[_site].path, dir
      else
        isAbsolute = true
        dir2 = path.resolve @config.sites[_site].path, dir2

      if dir2[dir2.length - 1] isnt '/'
        dir2 += '/'

      _path = path.resolve N.basePath, dir2
      try entries = fs.readdirSync _path

      if not entries?
        if fs.statSync _path .isDirectory!
          console.error 'Warning: Cannot read folder: ' + _path
          continue
        else
          _path = path.resolve @config.sites[_site].path
          entries = [dir]

      # console.log 'ENTRIES' ext, _path, entries
      files = _(entries).filter (entry) ~>
        fs.statSync(_path + \/ + entry).isFile() and
          entry.match (new RegExp '\.'+ext+'$', \gi) and !entry.match /\.min/g

      if rec
        folders = entries
          |> filter (entry) ~> fs.statSync(_path + \/ + entry).isDirectory() and not entry.match(/^\./g)
          |> map (folder) ~> path.resolve dir2, folder

        @SaveAssets _site, isAbsolute, name, _path, files, before
        @_GetFiles name, folders, ext, true, before

      if not rec
        @SaveAssets _site, isAbsolute, name, dir2, files, before

  SaveAssets: (_site, isAbsolute, name, _path, files, before) ->
    if isAbsolute
      files = _(files).map (file) ~>
        _mount = @config.sites[_site].mount
        if _mount is \/
          _mount = ''

        if file.split('.')[*-1] is 'coffee'
          file.replace /\.coffee/g, '.js'
        else if file.split('.')[*-1] is 'ls'
          file.replace /\.ls/g, '.js'
        else
          file

    # console.log 'SAVE RESOLVE' _path, files
    files = files
      |> map (file) ~> path.resolve _path, file
      |> map (file) ~>
        file.replace new RegExp("#{N.appRoot}/", 'gi'), ''
      |> map (file) ~>
        file.replace new RegExp("#{N.libRoot}/", 'gi'), ''

    if not @list[name]
      @list[name] = files
    else
      /*if before
        @list[name] = files.concat @list[name]
      else*/
      @list[name] = @list[name].concat files
    # console.log 'Saved' files


  AddFoldersRec: (list, _ext, before = false) ->
    for name, dirs of list
      ext = _ext || ((name.split \/ |> reverse |> (.0)).split \. |> reverse |> (.0))
      @_GetFiles name, dirs, ext, true, before

  AddFolders: (list, _ext, before = false) ->
    for name, dirs of list
      ext = _ext || ((name.split \/ |> reverse |> (.0)).split \. |> reverse |> (.0))
      @_GetFiles name, dirs, ext, before

  _Serve: ->
    if @config.minified
      @_InitGrunt()
      @_RunGrunt()

    @compiled = {}
    Compile = (site) ~>
      jcompile = {}
      if N.modules.angular?
        jcompile = _(jcompile).extend N.modules.angular.Compile()

      for name, list of @list
        site_ = name.split('/')[name.split('/').length - 1].split('.')[0]
        @compiled[site_] = jcompile[site_]() if not @compiled[site_]? and jcompile[site_]?
        # console.log "AFTER ANGULAR" @compiled[site_]

      @compiled[site] || ''

    url_to_paths = {}
    if @config.minified
      for site, config of @config.sites
        Compile site

    if not @config.minified

      for site, paths of @list
        if site.split('/')[site.split('/').length - 1].split('.')[2] is 'js'
          @list[site] = _(paths).map (item) ->
            if item.split('.')[1] is 'coffee'
              item.replace /\.coffee/g, '.js'
            else
              item
      /*console.log @list[site]*/

      N.app.use coffeeMiddleware do
        src: path.resolve N.appRoot, '.'
        prefix: 'coffee'
        bare: true
        force: true

      N.app.use coffeeMiddleware do
        /*src: path.resolve \/home/fgreiner/prog/js/Nodulator/node_modules/nodulator-angular/assets*/
        src: N.libRoot
        prefix: 'coffee'
        bare: true
        force: true

    # N.app.use minify()
    N.app.use require('connect-cachify').setup @list,
      root: path.join N.appRoot, '.'
      # root:  N.appRoot
      #url_to_paths: {'/img/': '/client/public/img'}
      url_to_paths: {'/out/': '\/home/fgreiner/prog/js/Nodulator/node_modules/nodulator-angular/assets'}
      production: @config.minified
      # debug: true
    for site, config of @config.sites
      for destPath, origPath of @config.sites[site].public
        for p in origPath
          if p[0] is '/'
            p = '.' + p

          N.app.use "#{destPath}",  N.express.static path.resolve N.appRoot, p

    if not @config.minified
      N.app.use N.express.static path.resolve N.appRoot
    else
      for name, paths of @list
        siteName = name.split('/')[name.split('/').length - 1]
        site = '/' + siteName.split('.')[0] + '/' + siteName.split('.')[siteName.split('.').length - 1] + name
        N.app.use name,  N.express.static path.resolve N.appRoot, name[1 to]*''

    N.app.use cookieParser 'nodulator'

    N.app.set 'views', path.resolve N.appRoot
    N.app.engine '.' + @config.engine, jade.__express
    N.app.set 'view engine', @config.engine

    N.app.use (req, res, next) ~>

      res.locals.nodulator = (site = 'root') ~>
        comp = {}
        if not @config.minified
          @compiled = {}
          # console.log 'TMERE' site
          comp = Compile site
        else
          comp = @compiled[site] || ''

        _path = "#{@config.sites[site].path}/#{site}.min."

        /*if N.modules.angular?
          comp += res.locals.cachify_js "/nodulator-angular.min.js"*/

        # console.log "TROLL #{@config.sites[site].path}/#{site}.vendors_min.js"

        comp += a = res.locals.cachify_js "#{@config.sites[site].path}/#{site}.vendors_min.js"
        comp += res.locals.cachify_js "#{_path}js" if @list["#{_path}js"].length
        comp += res.locals.cachify_css "#{_path}css" if @list["#{_path}css"].length
        # console.log 'COMP' a

        if N.AccountResource?
          comp += N.AccountResource._AccountResource._InjectUser req

        comp

      next()

  AddView: (view, site = 'root') ->
    @views[site] = '' if not @views[site]?
    @views[site] += view

module.exports = NAssets
