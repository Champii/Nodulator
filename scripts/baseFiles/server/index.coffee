fs = require 'fs'
path = require 'path'

exports.Init = ->
  basePath = __dirname

  folders = ['sockets', 'processors', 'resources']
  require(path.join basePath, folder).Init() for folder in folders

