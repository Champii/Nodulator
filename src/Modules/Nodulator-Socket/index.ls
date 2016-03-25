socket = require 'socket.io'
cookieParser = require 'cookie-parser'
passportSocketIO = require "passport.socketio"

io = null
prefixes = ['new_', 'update_', 'delete_']

NModule = require \../NModule

class NSocket extends NModule

  name: \NSocket

  defaultConfig:
    store:
      type: 'redis'

  @rooms = []

  Init: ->

    @_OverrideResource!

    N.Route._InitServer!
    @_InitSockets!

  _OverrideResource: ->
    oldResource = N.Resource
    N.Resource = (name, routes, config, _parent) ->
      if not @resources[name.toLowerCase()]?
        @bus.emit 'new_resource', name

      oldResource.call N, name, routes, config, _parent

  _InitSockets: ->
    @io = socket.listen N.server
    N.io = @io
    io = @io
    onAuthorizeSuccess = (data, accept) ->
      accept null, true

    onAuthorizeFail = (data, message, error, accept) ->
      # return accept new Error message if error

      accept null, false

    if N.AccountResource?
      @io.use passportSocketIO.authorize do
        passport:       N.passport
        cookieParser:   cookieParser
        key:            'N'
        secret:         'N'
        store:          N.sessionStore
        success:        onAuthorizeSuccess
        fail:           onAuthorizeFail

    @io.sockets.on 'connection', (socket) ~>

      NSocket.JoinRooms socket

      socket.once 'disconnect', ~>
        @OnDisconnect socket if @OnDisconnect?

      @OnConnect socket if @OnConnect?

  Close: ->
    @io.server.close! if @io.server?

  GetSocket: (userId) ->
    sockets = passportSocketIO.filterSocketsByUser @io, (user) ->
      user.id is userId
    sockets?[0]

  @JoinRoom = (socket, instance) ->
    # console.log 'join', instance._type
    socket.join instance._type + '-' + instance.id

  JoinRoom: NSocket.JoinRoom

  @JoinRooms = (socket) ->
    for room in NSocket.rooms
      socket.join room
  #
  @EmitRoom = (instance, ...args) ->
    # console.log 'emit', instance
    room = io.sockets.in(instance)
    # console.log 'room', room, args
    for k, v of args
      if v.ToJSON?
        args[k] = v.ToJSON!
    room.emit.apply room, args
  #
  @NewRoom = (name) ->
    @rooms.push name
    for prefix in prefixes
      do (prefix) ->
        N.bus.on prefix + name, (item) ~>
          NSocket.EmitRoom name, prefix + name, item

  @Init = ->
    res = @
    N.socket = new res

N.bus.on 'new_resource', (name) ->
  # console.log 'New_resource', name
  NSocket.NewRoom name


#N.Socket = ->
#  NSocket

module.exports = NSocket
