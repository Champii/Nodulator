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
        @List()
      , false

    OnNew: (item) ->
      @list.push item

    OnUpdate: (item) ->
      toChange = _(@list).findWhere id: item.id
      toChange = _(toChange).extend item

    OnDelete: (item) ->
      @list = _(@list).reject (i) -> i.id is item.id

    List: (done) ->
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

    Delete: (id, done) ->
      @$http.delete '/api/1/' + @_resName + '/' + id
        .success (data) =>
          done() if done?
        .error (data) ->
          done data if done?

    Add: (blob, done) ->
      @$http.post '/api/1/' + @_resName, blob
        .success (data) =>
          done null, data if done?
        .error (data) ->
          done data if done?

    Update: (blob, done) ->
      @$http.put '/api/1/' + @_resName + '/' + blob.id, blob
        .success (data) =>
          done null, data if done?
        .error (data) ->
          done data if done?
