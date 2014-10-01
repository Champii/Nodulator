_ = require 'underscore'
async = require 'async'
assert = require 'assert'

Client = require './common/client'

Modulator = require '../lib/Modulator'

client = null

PlayerResource = null
TestResource = null

describe 'Modulator Account', ->

  before (done) ->
    Modulator.Reset ->

      PlayerResource = Modulator.Resource 'player',
        account: true
        restrict: 'user'

      TestResource = Modulator.Resource 'test',
        restrict: 'auth'

      RestrictedResource = Modulator.Resource 'restricted',
        restrict:
          group: 1

      assert PlayerResource?
      assert TestResource?

      client = new Client Modulator.app

      async.auto
        user1: (done) -> client.Post '/api/1/players', {username: 'user1', password: 'pass', test: 'test', group: 1}, done
        login: ['user1', (done) -> client.SetIdentity('user1', 'pass') and client.Login done ]
        test1: ['login', (done, results) -> client.Post '/api/1/tests', {nb: 1}, done ]
        user2: ['test1', (done, results) -> client.Post '/api/1/players', {username: 'user2', password: 'pass', test: 'test', group: 2}, done ]
        restricted: ['user2', (done, results) -> client.Post '/api/1/restricteds', {nb: 2}, done ]
        logout: ['restricted', (done) -> client.Logout done ]
      , (err, results) ->
        throw new Error err if err?

        done()

  it 'should refuse access to TestResource', (done) ->
    client.Get '/api/1/tests', (err, res) ->
      throw new Error 'Got access' if not err?

      done()

  it 'should refuse access to RestrictedResource', (done) ->
    client.Get '/api/1/restricteds', (err, res) ->
      throw new Error 'Got access' if not err?

      done()

  it 'should login user1', (done) ->
    client.SetIdentity 'user1', 'pass'

    client.Login (err) ->
      throw new Error err if err?

      done()

  it 'should have access to RestrictedResource', (done) ->
    client.Get '/api/1/restricteds', (err, res) ->
      throw new Error err if err?

      done()

  it 'should now have access to TestResource', (done) ->
    client.Get '/api/1/tests', (err, res) ->
      throw new Error err if err?

      done()

  it 'should allow user to PUT on self UserReource', (done) ->
    client.Put '/api/1/players/1', {test: 'test2'}, (err, res) ->
      throw new Error err if err?

      done()

  it 'should login user2', (done) ->
    client.Logout (err) ->
      throw new Error err if err?

      client.SetIdentity 'user2', 'pass'

      client.Login (err) ->
        throw new Error err if err?

        done()

  it 'should refuse access to RestrictedResource', (done) ->
    client.Get '/api/1/restricteds', (err, res) ->
      throw new Error 'Got access' if not err?

      done()

  it 'should deny acces to other users', (done) ->
    client.Put '/api/1/players/1', {test: 'test3'}, (err, res) ->
      return done() if err?

      throw new Error 'Got access'
