socket = require 'socket.io'
cookieParser = require 'cookie-parser'
passportSocketIO = require("passport.socketio");

bus = require './Bus'

io = null
class Socket

  @rooms: []

  constructor: (@server, @store, @passport) ->

    @io = socket.listen @server
    io = @io
    onAuthorizeSuccess = (data, accept) ->
      console.log 'success'
      accept(null, true);

    onAuthorizeFail = (data, message, error, accept) ->
      console.log 'fail', message, error
      # return accept new Error message if error

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

      socket.on 'lol', ->
        console.log 'lol'

      Socket.JoinRooms socket

      socket.once 'disconnect', () ->

  @JoinRooms: (socket) ->
    for room in Socket.rooms
      socket.join room

  @EmitRoom: (name, args...) ->
    room = io.sockets.in(name)
    room.emit.apply room, args
    console.log 'Emit', name, args

  @NewRoom: (name) ->
    @rooms.push name
    for prefix in prefixes
      do (prefix) ->
        console.log 'Added for', prefix + name
        bus.on prefix + name, (item) =>
          console.log 'Event', prefix + name, item
          Socket.EmitRoom name, prefix + name, item

module.exports = Socket

prefixes = ['new_', 'update_', 'delete_']
