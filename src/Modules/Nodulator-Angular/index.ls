fs = require 'fs'
path = require 'path'
jade = require 'jade'
_ = require 'underscore'

NModule = require '../NModule'

class NAngular extends NModule

  compiled: ''
  name: 'NAngular'

  defaultConfig:
    servicesPath: 'services'
    directivesPath: 'directives'
    controllersPath: 'controllers'
    factoriesPath: 'factories'
    templatesPath: 'views'

  Init: ->
    if not N.modules.assets?
      throw new Error 'N-Angular needs N-Assets to work'

    if not N.modules.socket?
      throw new Error 'N-Angular needs N-Socket to work'

    for site, obj of N.config.modules.assets.sites
      o = {}
      o["#{N.config.modules.assets.sites[site].path}/#{site}.min.js"] = [
        @config.servicesPath
        @config.directivesPath
        @config.controllersPath
        @config.factoriesPath
        path.resolve __dirname, '../../../node_modules/nodulator-angular/assets'
      ]

      N.modules.assets.AddFoldersRec o, \coffee

  InjectViewsRec: (site, _path) ->
    dirPath = path.resolve N.appRoot, \./ + N.config.modules.assets.sites[site].path, \./ + _path

    try files = fs.readdirSync  dirPath

    j = ''
    f = []
    for file in files
      stat = fs.statSync dirPath + '/' + file
      if stat.isDirectory()
        [j_, f_] = @InjectViewsRec site, _path + '/' + file
        f = f.concat  f_
        j += j_
      else
        if file[0] isnt '.' and file.split('.')[1] is 'jade'
          f.push file.split('.')[0]
          j += '\n'
          j += 'script#' + file.split('.')[0] + '-tpl(type="text/ng-template")\n'
          j += '  include '+ N.config.modules.assets.sites[site].path + \/ + _path + '/' + file.split('.')[0] + '\n'

    [j, f]

  ListDirectives: (site, path = '/') ->
    dirPath = N.appRoot + N.config.modules.assets.sites[site].path + @config.directivesPath + path
    try files = fs.readdirSync dirPath
    catch e
      return 0

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

    [j, f] = @InjectViewsRec site, @config.templatesPath

    j += '
      script#_nodulator-assets' + "
        var _views = #{JSON.stringify f};
        var _nbDirectives = #{@ListDirectives(site)};
        var _resources = #{JSON.stringify _(N.resources).keys()};\n
    "

    j += "
       script(src=\"/socket.io/socket.io.js\")
    "
    j

  Compile: ->
    jcompile = {}
    for site, obj of N.config.modules.assets.sites
      N.modules.assets.views[site] = ''
      N.modules.assets.AddView @InjectViews(site), site

      console.log \COMPILE N.modules.assets.views[site]
      jcompile[site] = N.modules.assets.engine.compile N.modules.assets.views[site],
        filename: path.resolve N.appRoot, \./ + obj.path
    jcompile


module.exports = NAngular
