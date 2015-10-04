class UserService extends Nodulator.Service 'user', '$http', '$window', 'socket'

  current: null

  Init: ->
    if __user.id?
      @current = __user

  Logout: ->
    @$http.post('/api/1/clients/logout')
      .success (data) ->
        @$window.location.href = '/'

UserService.Init()
