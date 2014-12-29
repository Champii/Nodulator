path = require 'path'

exports.Init = ->
  folders = require './loadOrder'
  require('./' + folder).Init() for folder in folders

