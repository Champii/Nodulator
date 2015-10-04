fs = require 'fs'
path = require 'path'
jade = require 'jade'
_ = require 'underscore'

module.exports = (Nodulator) ->

  class Nangulator

    compiled: ''
    name: 'Angular'

    constructor: ->
      if not Nodulator.assets?
        throw new Error 'Nodulator-Angular needs Nodulator-Assets to work'

      if not Nodulator.Socket?
        throw new Error 'Nodulator-Angular needs Nodulator-Socket to work'

      Nodulator.ExtendDefaultConfig
        servicesPath: '/services'
        directivesPath: '/directives'
        controllersPath: '/controllers'
        factoriesPath: '/factories'
        templatesPath: '/views'

      Nodulator.Config() if not Nodulator.config?

      for site, obj of Nodulator.config.assets
        o = {}
        o["/js/#{site}.js"] = [
          '/node_modules/nodulator-angular/assets'
          obj.path + Nodulator.config.servicesPath
          obj.path + Nodulator.config.directivesPath
          obj.path + Nodulator.config.controllersPath
          obj.path + Nodulator.config.factoriesPath
        ]

        Nodulator.assets.AddFoldersRec o

    InjectViewsRec: (site, path) ->
      dirPath = Nodulator.appRoot + Nodulator.config.assets[site].path + path

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
            j += '  include '+ Nodulator.config.assets[site].path[1..] + path + '/' + file.split('.')[0] + '\n'

      [j, f]

    ListDirectives: (site, path = '/') ->
      dirPath = Nodulator.appRoot + Nodulator.config.assets[site].path + Nodulator.config.directivesPath + path
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

      [j, f] = @InjectViewsRec site, Nodulator.config.templatesPath

      j += "
        script#_nodulator-assets
          var _views = #{JSON.stringify f};
          var _nbDirectives = #{@ListDirectives(site)};
          var _resources = #{JSON.stringify _(Nodulator.resources).keys()};\n
      "

      j += '''
        script(src="/socket.io/socket.io.js")
      '''

    Compile: ->
      jcompile = {}
      for site, obj of Nodulator.config.assets
        Nodulator.assets.views[site] = ''
        Nodulator.assets.AddView @InjectViews(site), site

        jcompile[site] = Nodulator.assets.engine.compile Nodulator.assets.views[site],
          filename: path.resolve Nodulator.appRoot, Nodulator.config.viewRoot
      jcompile


  Nodulator.nangulator = new Nangulator
