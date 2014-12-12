class Socket extends Factory 'socket', '$rootScope'

  constructor: ->
    @socket = io()
    console.log 'Socket = ', @socket
    @socket.emit 'lol'
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

Socket.Init()
