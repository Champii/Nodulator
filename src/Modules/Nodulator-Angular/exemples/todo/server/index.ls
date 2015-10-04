fs = require 'fs'
path = require 'path'

exports.Init = ->
  basePath = __dirname

  folders = ['sockets', 'processors', 'resources']
  for folder in folders
    require(path.join basePath, folder).Init()
