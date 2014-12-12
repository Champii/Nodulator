ResourceService = (name, injects) ->

  if '$http' not in injects
    injects.push '$http'
  if 'socket' not in injects
    injects.push 'socket'

  class _ResourceService extends Service name, injects

    list: []
    _resName: name + 's'

    FetchAll: (done) ->
      @$http.get '/api/1/' + @_resName
        .success (data) =>
          @list = data
          done null, @list if done?
        .error (data) ->
          done data if done?
