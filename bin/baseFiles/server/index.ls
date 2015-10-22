path = require \path

exports.Init = ->
  folders = require \./loadOrder
  for folder in folders
    require \./ + folder .Init!
