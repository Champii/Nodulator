fs = require 'fs'
path = require 'path'

exports.Init = ->
  basePath = __dirname

  folders = ['processors', 'resources', 'sockets']
  require(path.join basePath, folder).Init() for folder in folders

