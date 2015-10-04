http = require 'http'
path = require 'path'
express = require 'express'
expressSession = require 'express-session'
passport = require 'passport'
cookieParser = require 'cookie-parser'
bodyParser = require 'body-parser'

routes = require '../../routes'
sockets = require '../../socket/socket'
processors = require '../../processors'
bus = require '../../bus'

mecaRoot = path.resolve __dirname, '../..'

class Server

  constructor: ->
    @app = null
    @server = null

  Start: (done) ->
    return if @app?

    @app = express()

    @app.use cookieParser()
    @app.use bodyParser()
    @app.use expressSession secret: 'mecanicadom secret'

    @app.use express.static path.resolve mecaRoot, 'public'

    @app.use passport.initialize()
    @app.use passport.session()

    routes.mount @app

    processors.init()

    @server = http.createServer @app

    @server.listen 3000

    sockets.init @server

    done()


  Stop: ->
    return if !(@app?)

    @app = null
    @server = null



module.exports = Server
