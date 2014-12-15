class Socket extends Modulator.Factory 'socket', '$rootScope'

  socket: {}

  constructor: ->
    super()

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
    r = new res
    document.addEventListener "DOMContentLoaded", (event) ->
      r.socket = io()

Socket.Init()
