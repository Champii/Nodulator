_ = require 'underscore'
async = require 'async'
assert = require 'assert'

Client = require './common/client'

Modulator = require '../lib/Modulator'

client = null

UserResource = null
TestResource = null

describe 'Modulator Account', ->

  before (done) ->
    Modulator.Reset ->

      UserResource = Modulator.Resource 'user',
        account: true

      TestResource = Modulator.Resource 'test',
        restrict:
          resource: UserResource
          foreignId: 'user_id'

      assert UserResource?
      assert TestResource?

      client = new Client Modulator.app

      async.auto
        user1: (done) -> client.Post '/api/1/users', {username: 'user1', password: 'pass', test: 'test'}, done
        test1: ['user1', (done, results) -> client.Post '/api/1/tests', {user_id: results.user1.body.id, nb: 1}, done ]
        user2: ['test1', (done, results) -> client.Post '/api/1/users', {username: 'user2', password: 'pass', test: 'test'}, done ]
        test2: ['user2', (done, results) -> client.Post '/api/1/tests', {user_id: results.user2.body.id, nb: 2}, done ]
      , (err, results) ->
        throw new Error err if err?

        done()

  it 'should login user1', (done) ->
    client.SetIdentity 'user1', 'pass'

    client.Login (err) ->
      throw new Error err if err?

      done()

  it 'should allow user to PUT on self UserReource', (done) ->
    client.Put '/api/1/users/1', {test: 'test2'}, (err, res) ->
      throw new Error err if err?

      done()

  it 'should login user2', (done) ->
    client.Logout (err) ->
      throw new Error err if err?

      client.SetIdentity 'user2', 'pass'

      client.Login (err) ->
        throw new Error err if err?

        done()

  it 'should deny acces to other users', (done) ->
    client.Put '/api/1/users/1', {test: 'test3'}, (err, res) ->
      return done() if err?

      throw new Error 'Error'
