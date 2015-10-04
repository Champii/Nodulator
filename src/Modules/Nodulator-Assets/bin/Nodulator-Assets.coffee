fs = require 'fs'
path = require 'path'
exec = require('child_process').exec
async = require 'async'

NodulatorRoot = path.resolve __dirname, '..'
appRoot = path.resolve '.'

module.exports = (done) ->
  async.series [
    (done) ->
      process.stdout.write '  Create base folder..............'
      exec 'mkdir -p ' + appRoot + '/client/', done

    (done) ->
      process.stdout.write 'Ok\n'
      process.stdout.write '  Init base folder tree...........'
      exec 'cp -ran ' + (path.resolve NodulatorRoot, 'bin/baseFiles') + '/* ' + appRoot + '/client/', done]

    , (err, results) ->
      return done err if err?

      process.stdout.write 'Ok\n'
      done()
