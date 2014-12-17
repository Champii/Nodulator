fs = require 'fs'
path = require 'path'

exports.Init = ->
  basePath = __dirname

  fs.readdirSync(basePath).forEach (fileName) ->
    return 0 if fileName is 'index.coffee'

    filePath = path.join basePath, fileName
    fileStat = fs.statSync filePath

    require(filePath).Init() if fileStat.isFile()
