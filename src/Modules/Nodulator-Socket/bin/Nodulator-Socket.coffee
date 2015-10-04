fs = require 'fs'
path = require 'path'
exec = require('child_process').exec
async = require 'async'

moduleRoot = path.resolve __dirname, '..'
appRoot = path.resolve '.'

module.exports = (done) ->
  async.series [
    (done) ->
      process.stdout.write '  Create base folder..............'
      exec 'mkdir -p ' + appRoot + '/client/', done

    (done) ->
      process.stdout.write 'Ok\n'
      process.stdout.write '  Init base folder tree...........'
      exec 'cp -ran ' + (path.resolve moduleRoot, 'bin/baseFiles') + '/* ' + appRoot, done

    (done) ->
      process.stdout.write 'Ok\n'
      process.stdout.write '  Adding Socket to loadOrder......'
      orderPath = appRoot + '/server/loadOrder.json'
      loadOrder = JSON.parse fs.readFileSync orderPath
      if 'sockets' not in loadOrder
        loadOrder.unshift 'sockets'
        fs.writeFile orderPath, JSON.stringify(loadOrder), done
      else
        done()]

    , (err, results) ->
      return done err if err?

      process.stdout.write 'Ok\n'
      done()
