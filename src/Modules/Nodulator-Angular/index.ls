fs = require 'fs'
path = require 'path'
jade = require 'jade'
_ = require 'underscore'

NModule = require '../NModule'

class NAngular extends NModule

  compiled: ''
  name: 'NAngular'

  defaultConfig:
    servicesPath: '/services'
    directivesPath: '/directives'
    controllersPath: '/controllers'
    factoriesPath: '/factories'
    templatesPath: '/views'

  Init: ->
    if not N.modules.assets?
      throw new Error 'N-Angular needs N-Assets to work'

    if not N.modules.socket?
      throw new Error 'N-Angular needs N-Socket to work'

    for site, obj of N.config.assets
      o = {}
      o["#{N.config.assets[site].path}/public/#{site}.min.js"] = [
        '/node_modules/nodulator-angular/assets'
        obj.path + @config.servicesPath
        obj.path + @config.directivesPath
        obj.path + @config.controllersPath
        obj.path + @config.factoriesPath
      ]

      N.modules.assets.AddFoldersRec o

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
          j += '  include '+ N.config.assets[site].path[1 to]*'' + path + '/' + file.split('.')[0] + '\n'

    [j, f]

  ListDirectives: (site, path = '/') ->
    dirPath = N.appRoot + N.config.assets[site].path + @config.directivesPath + path
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

    [j, f] = @InjectViewsRec site, @config.templatesPath

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
      N.modules.assets.views[site] = ''
      N.modules.assets.AddView @InjectViews(site), site

      jcompile[site] = N.assets.engine.compile N.modules.assets.views[site],
        filename: path.resolve N.appRoot, N.config.assets.viewRoot
    jcompile


module.exports = NAngular
