fs = require 'fs'
path = require 'path'
exec = require('child_process').exec
async = require 'async'

moduleRoot = path.resolve __dirname, '..'
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
      process.stdout.write '  Init base folder tree...........'
      exec 'cp -ran ' + (path.resolve moduleRoot, 'bin/assets/server/') + '/* ' + appRoot + '/server', (err, stdout, stderr) ->
        # return done err if err?

        process.stdout.write 'Error ' + err + '\n' if err?
        process.stdout.write 'Ok\n' if not err?
        done()

    (done) ->
      exists 'node_modules/nodulator-assets', (exist) ->
        if not exist
          return done()

        exists 'node_modules/nodulator-angular', (exist) ->
          if not exist
            process.stdout.write '  Adding View support.............'
            return exec 'cp -ran ' + (path.resolve moduleRoot, 'bin/assets/client_brut/') + '/* ' + appRoot + '/client', (err, stdout, stderr) ->
              # return done err if err?

              process.stdout.write 'Error\n' if err?
              process.stdout.write 'Ok\n' if not err?
              done()

          process.stdout.write '  Adding Angular support..........'
          exec 'cp -ran ' + (path.resolve moduleRoot, 'bin/assets/client_angular/') + '/* ' + appRoot + '/client', (err, stdout, stderr) ->
            # return done err if err?

            process.stdout.write 'Error\n' if err?
            process.stdout.write 'Ok\n' if not err?
            # process.stdout.write 'Ok\n'
            done()

    ], (err, results) ->
      return done err if err?

      done()
