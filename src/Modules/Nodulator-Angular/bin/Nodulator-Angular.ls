fs = require 'fs'
path = require 'path'
exec = require('child_process').exec
async = require 'async'

NRoot = path.resolve __dirname, '..'
appRoot = path.resolve '.'

exists = (path, done) ->
  fs.open path, 'r', (err, fd) ->
    if err?
      done false
    else
      fs.closeSync fd
      done true

module.exports = (done) ->
  async.series [
    (done) ->
      process.stdout.write '  Create base folder..............'
      exec 'mkdir -p ' + appRoot + '/client/', done

    (done) ->
      process.stdout.write 'Ok\n'
      process.stdout.write '  Init base folder tree...........'
      exec 'cp -ran ' + (path.resolve NRoot, 'bin/baseFiles') + '/* ' + appRoot + '/client/', done

    (done) ->
      process.stdout.write 'Ok\n'
      process.stdout.write '  Downloading AngularJS v1.3.8....'
      exists appRoot + '/client/public/js/angular.js', (exist) ->
        if exist
          process.stdout.write 'Exists\n'
          return done()

        exec 'wget https://code.angularjs.org/1.3.8/angular.js -O ' + appRoot + '/client/public/js/angular.js', (err) ->
          return done err if err?

          process.stdout.write 'Ok\n'
          done()

  ], (err, results) ->
      return done err if err?

      done()
