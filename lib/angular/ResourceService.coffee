ResourceService = (name, injects) ->

  if '$http' not in injects
    injects.push '$http'
  if 'socket' not in injects
    injects.push 'socket'

  console.log 'ResourceService', injects
  class _ResourceService extends Service name, injects

    list: []
    current: null
    _resName: name + 's'
    _lName: name

    Init: ->
      console.log 'Init', @_lName
      @socket.On 'new_' + @_lName, (item) => console.log 'New', item
      @socket.On 'update_' + @_lName, (item) => console.log 'Update', item
      @socket.On 'delete_' + @_lName, (item) => console.log 'Delete', item

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
