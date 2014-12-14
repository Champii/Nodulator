class Socket extends Modulator.Factory 'socket', '$rootScope'

  socket: {}

  constructor: ->
    super()
    @socket = io()

  On: (eventName, callback) ->
    wrapper = =>
      args = arguments
      @$rootScope.$apply =>
        callback.apply @socket, args

    @socket.on eventName, wrapper

    return =>
      @socket.removeListener eventName, wrapper

  Emit: (eventName, data, callback) ->
    @socket.emit eventName, data, =>
      args = arguments
      @$rootScope.$apply =>
        if callback
          callback.apply @socket, args

  @Init: ->
    res = @
    new res

    # console.log 'Socket = ', @socket
    # s.socket.Emit 'lol'

document.addEventListener "DOMContentLoaded", (event) ->
  Socket.Init()
