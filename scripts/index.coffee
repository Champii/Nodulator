#
# Nodulator Boostrap
#
# Usage: Nodulator init
#
fs = require 'fs'
path = require 'path'
exec = require('child_process').exec
async = require 'async'

args = process.argv[2..]

NodulatorRoot = path.resolve __dirname, '..'
appRoot = path.resolve '.'
console.log NodulatorRoot, appRoot

usage = ->
  console.error 'Usage: Nodulator init'

if args.length != 1 or args[0] != 'init'
  return usage()

async.series [
  (done) ->
    console.log 'Init base folder tree'
    exec 'cp -r ' + (path.resolve NodulatorRoot, 'scripts/baseFiles/') + '/* ' + appRoot, done

  (done) ->
    console.log 'Ok'
    console.log ''
    console.log 'Installing base packages'
    exec 'cd ' + appRoot + '&& mkdir -p node_modules && npm install', done

  (done) ->
    console.log 'Ok'
    console.log ''
    console.log 'Installing Nodulator from LINK'
    exec 'ln -fs ' + NodulatorRoot + ' ' + (path.resolve appRoot, 'node_modules'), done

  (done) ->
    console.log 'Ok'
    console.log ''
    console.log 'Installing Nodulator angular from LINK'
    exec 'ln -fs ' + NodulatorRoot + '/lib/angular ' + appRoot + '/client/public/js/Nodulator-angular', done]

  , (err, results) ->
    return console.error err if err?

    console.log 'Ok'
    console.log ''
    console.log 'Done'
