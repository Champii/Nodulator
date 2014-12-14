socket = require 'socket.io'
cookieParser = require 'cookie-parser'
passportSocketIO = require "passport.socketio"

bus = require './Bus'

io = null
prefixes = ['new_', 'update_', 'delete_']

module.exports = (Modulator) ->
  class Socket

    @rooms: []

    constructor: ->

      @io = socket.listen Modulator.server
      io = @io
      onAuthorizeSuccess = (data, accept) ->
        accept null, true

      onAuthorizeFail = (data, message, error, accept) ->
        # return accept new Error message if error

        accept null, false

      @io.use passportSocketIO.authorize
        passport:       Modulator.passport
        cookieParser:   cookieParser
        key:            'modulator'
        secret:         'modulator'
        store:          Modulator.sessionStore
        success:        onAuthorizeSuccess
        fail:           onAuthorizeFail

      @io.sockets.on 'connection', (socket) =>

        Socket.JoinRooms socket

        socket.once 'disconnect', () =>
          @OnDisconnect socket if @OnDisconnect?

        @OnConnect socket if @OnConnect?

    Close: ->
      @io.server.close() if @io.server?

    @JoinRooms: (socket) ->
      for room in Socket.rooms
        socket.join room

    @EmitRoom: (name, args...) ->
      room = io.sockets.in(name)
      room.emit.apply room, args

    @NewRoom: (name) ->
      @rooms.push name
      for prefix in prefixes
        do (prefix) ->
          bus.on prefix + name, (item) =>
            Socket.EmitRoom name, prefix + name, item

    @Init: ->
      res = @
      Modulator.socket = res
      new res
