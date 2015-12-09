fs = require 'fs'
path = require 'path'
jade = require 'jade'
_ = require 'underscore'

module.exports = (N) ->

  class Nangulator

    compiled: ''
    name: 'Angular'

    constructor: ->
      if not N.assets?
        throw new Error 'N-Angular needs N-Assets to work'

      if not N.Socket?
        throw new Error 'N-Angular needs N-Socket to work'

      N.ExtendDefaultConfig
        servicesPath: '/services'
        directivesPath: '/directives'
        controllersPath: '/controllers'
        factoriesPath: '/factories'
        templatesPath: '/views'

      N.Config() if not N.config?

      for site, obj of N.config.assets
        o = {}
        o["#{N.config.assets[site].path}/public/#{site}.min.js"] = [
          '/node_modules/nodulator-angular/assets'
          obj.path + N.config.servicesPath
          obj.path + N.config.directivesPath
          obj.path + N.config.controllersPath
          obj.path + N.config.factoriesPath
        ]

        N.assets.AddFoldersRec o

    InjectViewsRec: (site, path) ->
      dirPath = N.appRoot + N.config.assets[site].path + path

      try files = fs.readdirSync  dirPath

      j = ''
      f = []
      for file in files
        stat = fs.statSync dirPath + '/' + file
        if stat.isDirectory()
          [j_, f_] = @InjectViewsRec site, path + '/' + file
          f = f.concat  f_
          j += j_
        else
          if file[0] isnt '.' and file.split('.')[1] is 'jade'
            f.push file.split('.')[0]
            j += '\n'
            j += 'script#' + file.split('.')[0] + '-tpl(type="text/ng-template")\n'
            j += '  include '+ N.config.assets[site].path[1..] + path + '/' + file.split('.')[0] + '\n'

      [j, f]

    ListDirectives: (site, path = '/') ->
      dirPath = N.appRoot + N.config.assets[site].path + N.config.directivesPath + path
      files = fs.readdirSync dirPath

      res = 0
      for file in files
        stat = fs.statSync dirPath + '/' + file
        if stat.isDirectory()
          res += @ListDirectives site, path + '/' +  file
        else
          if file[0] isnt '.' and file.split('.')[1] is 'coffee'
            res++

      res

    InjectViews: (site) ->

      [j, f] = @InjectViewsRec site, N.config.templatesPath

      j += "
        script#_nodulator-assets
          var _views = #{JSON.stringify f};
          var _nbDirectives = #{@ListDirectives(site)};
          var _resources = #{JSON.stringify _(N.resources).keys()};\n
      "

      j += "
         script(src=\"/socket.io/socket.io.js\")
      "

    Compile: ->
      jcompile = {}
      for site, obj of N.config.assets
        N.assets.views[site] = ''
        N.assets.AddView @InjectViews(site), site

        jcompile[site] = N.assets.engine.compile N.assets.views[site],
          filename: path.resolve N.appRoot, N.config.viewRoot
      jcompile


  N.nangulator = new Nangulator
