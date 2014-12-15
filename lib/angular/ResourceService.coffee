ResourceService = (name, injects) ->

  if '$http' not in injects
    injects.push '$http'
  if 'socket' not in injects
    injects.push 'socket'

  class _ResourceService extends Service name, injects

    list: []
    current: null
    _resName: name + 's'
    _lName: name

    Init: ->
      window.addEventListener "load", (event) =>
        @socket.On 'new_' + @_lName, (item) => @OnNew item
        @socket.On 'update_' + @_lName, (item) => @OnUpdate item
        @socket.On 'delete_' + @_lName, (item) => @OnDelete item
      , false

    OnNew: (item) ->
      # console.log 'new_' + @_lName, item
    OnUpdate: (item) ->
      # console.log 'update_' + @_lName, item
    OnDelete: (item) ->
      # console.log 'delete_' + @_lName, item

    FetchAll: (done) ->
      @$http.get '/api/1/' + @_resName
        .success (data) =>
          @list = data
          done null, @list if done?
        .error (data) ->
          done data if done?

    Fetch: (id, done) ->
      @$http.get '/api/1/' + @_resName + '/' + id
        .success (data) =>
          @current = data
          done null, @current if done?
        .error (data) ->
          done data if done?
