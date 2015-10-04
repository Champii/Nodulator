socket = require 'socket.io'
cookieParser = require 'cookie-parser'
passportSocketIO = require "passport.socketio"

io = null
prefixes = ['new_', 'update_', 'delete_']

module.exports = (Nodulator) ->
  Nodulator.ExtendDefaultConfig
   store:
     type: 'redis'

  class Socket

    @rooms: []

    constructor: ->

      # @_OverrideResource()

      Nodulator.Config()
      Nodulator.Route._InitServer()
      @_InitSockets()

    # _OverrideResource: ->
    #   oldResource = Nodulator.Resource
    #   Nodulator.Resource = (name, routes, config, _parent) ->
    #     if not @resources[name.toLowerCase()]?
    #       @bus.emit 'new_resource', name
    #
    #     oldResource.call Nodulator, name, routes, config, _parent

    _InitSockets: ->
      @io = socket.listen Nodulator.server
      io = @io
      onAuthorizeSuccess = (data, accept) ->
        accept null, true

      onAuthorizeFail = (data, message, error, accept) ->
        # return accept new Error message if error

        accept null, false

      if Nodulator.AccountResource?
        @io.use passportSocketIO.authorize
          passport:       Nodulator.passport
          cookieParser:   cookieParser
          key:            'Nodulator'
          secret:         'Nodulator'
          store:          Nodulator.sessionStore
          success:        onAuthorizeSuccess
          fail:           onAuthorizeFail

      @io.sockets.on 'connection', (socket) =>

        # Socket.JoinRooms socket

        socket.once 'disconnect', () =>
          @OnDisconnect socket if @OnDisconnect?

        @OnConnect socket if @OnConnect?

    Close: ->
      @io.server.close() if @io.server?

    GetSocket: (userId) ->
      sockets = passportSocketIO.filterSocketsByUser @io, (user) ->
        user.id is userId
      sockets?[0]


    @JoinRoom: (socket, instance) ->
      console.log instance._type
      socket.join instance._type + '-' + instance.id

    JoinRoom: Socket.JoinRoom

    # @JoinRooms: (socket) ->
    #   for room in Socket.rooms
    #     socket.join room
    #
    @EmitRoom: (instance, args...) ->
      console.log instance._type
      room = io.sockets.in(instance._type)
      room.emit.apply room, args
    #
    # @NewRoom: (name) ->
    #   @rooms.push name
    #   for prefix in prefixes
    #     do (prefix) ->
    #       Nodulator.bus.on prefix + name, (item) =>
    #         Socket.EmitRoom name, prefix + name, item

    @Init: ->
      res = @
      Nodulator.socket = new res

  Nodulator.bus.on 'new_resource', (name) -> Socket.NewRoom name

  Nodulator.Socket = ->
    Socket

  {name: 'Socket'}
