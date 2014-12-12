socket = require 'socket.io'
cookieParser = require 'cookie-parser'
passportSocketIO = require("passport.socketio");

bus = require './Bus'

class Socket

  constructor: (@server, @store, @passport) ->

    @io = socket.listen @server

    onAuthorizeSuccess = (data, accept) ->
      accept(null, true);

    onAuthorizeFail = (data, message, error, accept) ->
      return accept new Error message if error

      accept(null, false);

    @io.use passportSocketIO.authorize
      passport:       @passport
      cookieParser:   cookieParser
      key:            'modulator'
      secret:         'modulator'
      store:          @store
      success:        onAuthorizeSuccess
      fail:           onAuthorizeFail

    @io.sockets.on 'connection', (socket) =>

      console.log 'Socket', socket.request.user
      @JoinRoom 'user', socket.request.user.id, socket

      socket.once 'disconnect', () ->

  EmitRoom: (name, id, args...) ->
    room = @io.sockets.in(name + '-' + id)
    room.emit.apply room, args

  JoinRoom: (name, id, socket) ->
    socket.join name + '-' + id
    bus.on name + id, () ->


module.exports = Socket
