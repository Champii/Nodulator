superagent = require 'superagent'
agent = superagent.agent()

class Client

  constructor: (@app) ->
    @identity =
      username: ''
      password: ''
    @request = require('supertest')(@app)

  Login: (done) ->
    @request
      .post('/api/1/players/login')
      .send(@identity)
      .expect(200)
      .end (err, res) ->
        return done err if err?

        agent.saveCookies res
        done()

  Logout: (done) ->
    @request
      .post('/api/1/players/logout')
      .expect(200)
      .end done

  Get: (url, done) ->
    req = @request.get url

    @AttachCookie req
    req.expect 200, done

  Post: (url, data, done) ->
    req = @request.post url

    @AttachCookie req
    req
      .send(data)
      .expect(200)
      .end done

  Put: (url, data, done) ->
    req = @request.put url

    @AttachCookie req
    req
      .send(data)
      .expect(200)
      .end done

  AttachCookie: (req) ->
    agent.attachCookies req

  SetIdentity: (login, pass) ->
    @identity.username = login
    @identity.password = pass

module.exports = Client
