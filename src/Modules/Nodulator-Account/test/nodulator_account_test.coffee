_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

Nodulator = require 'nodulator'
Account = require '../'
client = null
TestRoute = null
TestResource = null
Test2Route = null
Test2Resource = null

describe 'Nodulator Account', ->

  before (done) ->
    Nodulator.Use Account
    done()

  it 'should create account resource', (done) ->
    class TestRoute extends Nodulator.Route.DefaultRoute
      Config: ->
        @Get '/test', @Auth(), (req, res) =>
          res.sendStatus(200)

        @Get '/test2', @HasProperty(id:1), (req, res) =>
          res.sendStatus(200)

        @Get '/test3', @HasProperty(id:2), (req, res) =>
          res.sendStatus(200)

        super()

        @Get '/:id/test4', @IsOwn('id'), (req, res) =>
          res.sendStatus(200)

    class TestResource extends Nodulator.AccountResource 'test', TestRoute

    TestResource.Init()

    class Test2Route extends Nodulator.Route
      Config: ->
        super()
        @Put '/test', @Auth(), (req, res) ->
          res.sendStatus(200)


    class Test2Resource extends Nodulator.Resource 'test2', Test2Route

    Test2Resource.Init()

    client = new Client Nodulator.app

    client.Post '/api/1/tests', {username: 'user1', password: 'pass', test: 'test', group: 1}, (err, res) ->
      throw new Error err if err?
      throw new Error 'No results' if not res?

      throw new Error 'Bad field' if not res.body.username? or not res.body.test? or not res.body.group?

      done()

  it 'should refuse bad login', (done) ->
    client.Logout (err) ->
      throw new Error err if err?

      client.SetIdentity('user2', 'pass2')
      client.Login (err) ->
        throw new Error 'Has logged in' if not err?

        done()

  it 'should not allow call for non authenticated user', (done) ->
    client.Get '/api/1/tests/test', (err, data) ->
      throw new Error 'Has allowed to non authenticated user' if not err?

      done()

  it 'should not allow call for non authenticated user (2)', (done) ->
    client.Put '/api/1/test2s/test', {}, (err, data) ->
      throw new Error 'Has allowed to non authenticated user' if not err?

      done()

  it 'should allow login', (done) ->
    client.SetIdentity('user1', 'pass')
    client.Login (err) ->
      throw new Error err if err?

      done()

  it 'should allow call for authenticated user', (done) ->
    client.Get '/api/1/tests/test', (err, data) ->
      throw new Error err if err?

      done()

  it 'should allow call for authenticated user (2)', (done) ->
    client.Put '/api/1/test2s/test', {}, (err, data) ->
      throw new Error err if err?

      done()

  it 'should allow call for authenticated user with id == 1', (done) ->
    client.Get '/api/1/tests/test2', (err, data) ->
      throw new Error err if err?

      done()

  it 'should not allow call for authenticated user with id != 2', (done) ->
    client.Get '/api/1/tests/test3', (err, data) ->
      throw new Error 'Has allowed' if not err?

      done()

  it 'should allow call for authenticated user with id == 1', (done) ->
    client.Get '/api/1/tests/1/test4', (err, data) ->
      throw new Error err if err?

      done()

  it 'should not allow call for authenticated user with id != 2', (done) ->
    client.Get '/api/1/tests/2/test4', (err, data) ->
      throw new Error 'Has allowed' if not err?

      done()

  it 'should logout', (done) ->
    client.Logout (err) ->
      throw new Error err if err?

      done()


  # it 'should not access new resource'
