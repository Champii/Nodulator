LocalStrategy = require('passport-local').Strategy

class AccountResource extends N '_account', {abstract: true}

  @userField =
    usernameField: 'username'
    passwordField: 'password'


  @_InitPassport = ->

    N.passport.serializeUser (user, done) ~>
      done null, user.id

    N.passport.deserializeUser (id, done) ~>
      @Fetch id, (err, user) ->
        return done null, false if err? and err.status is 'not_found'
        return done 'Error deserialize user', null if err?
        done null, user

    N.passport.use new LocalStrategy @userField, (username, password, done) ~>
      constraints = {}
      constraints[@userField.usernameField] = username
      @Fetch constraints, (err, user) ~>
      # @[@methodName] username, (err, user) ~>
        return done err if err? and err.status isnt 'not_found'
        return done null, false, {message: 'Incorrect Username/password'} if err? or !(user?) or user[@userField.passwordField] isnt password
        return done null, user

  @_InitLoginRoutes = (resName) ->
    @app = N.app
    @app.post '/api/1/' + resName + 's' + '/login', N.passport.authenticate('local'), (req, res) ~>
      if @config? and @config.loginCallback?
        @config.loginCallback req, ->
          res.sendStatus(200)
      else
        res.sendStatus(200)

    @app.post '/api/1/' + resName + 's' + '/logout', (req, res) ~>
      if @config? and @config.logoutCallback?
        @config.logoutCallback req, ->
          req.logout()
          res.sendStatus(200)
      else
        req.logout()
        res.sendStatus(200)

  @_InjectUser = (req, res) ->
    userObject = '<script>var __user = ' + (JSON.stringify(req.user?.ToJSON() || {})) + ';</script>\n'

    #FIXME: dirty
    userObject

  ToJSON: ->
    blob = super()
    delete blob[AccountResource.userField.passwordField]
    blob

module.exports = AccountResource
