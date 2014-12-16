socket = require 'socket.io'
cookieParser = require 'cookie-parser'
passportSocketIO = require "passport.socketio"

bus = require './Bus'

io = null
prefixes = ['new_', 'update_', 'delete_']

module.exports = (Nodulator) ->
  class Socket

    @rooms: []

    constructor: ->

      @io = socket.listen Nodulator.server
      io = @io
      onAuthorizeSuccess = (data, accept) ->
        accept null, true

      onAuthorizeFail = (data, message, error, accept) ->
        # return accept new Error message if error

        accept null, false

      @io.use passportSocketIO.authorize
        passport:       Nodulator.passport
        cookieParser:   cookieParser
        key:            'Nodulator'
        secret:         'Nodulator'
        store:          Nodulator.sessionStore
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
      Nodulator.socket = res
      new res
