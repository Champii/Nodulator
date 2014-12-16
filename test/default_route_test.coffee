_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

Nodulator = require '../'

client = null
TestResource = null

class TestRoute extends Nodulator.Route.DefaultRoute

describe 'Nodulator Route', ->

  before (done) ->
    Nodulator.Reset ->
      TestResource = Nodulator.Resource 'test', TestRoute
      assert TestResource?
      TestResource.Init()

      client = new Client Nodulator.app
      done()


  it 'should add first resource (POST)', (done) ->
    client.Post '/api/1/tests', {test: 'test'}, (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal res.body.test, 'test'
      done()

  it 'should fetch first resource (GET)', (done) ->
    client.Get '/api/1/tests/1', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal res.body.test, 'test'
      done()

  it 'should list all resources (GET)', (done) ->
    client.Get '/api/1/tests', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.length, 1
      done()

  it 'should save changed resource (PUT)', (done) ->
    async.auto
      test: (done) ->
        client.Get '/api/1/tests/1', (err, res) ->
          return done err if err?

          done null, res.body

      change: ['test', (done, results) ->
        results.test.test = 'test2'
        client.Put '/api/1/tests/1', results.test, done]

    , (err, results) ->
      throw new Error err if err?

      client.Get '/api/1/tests/1', (err, res) ->
        throw new Error err if err?

        assert res.body.test, 'test2'
        done()

  it 'should delete resource (DELETE)', (done) ->
    client.Delete '/api/1/tests/1', (err, res) ->
      throw new Error err if err?

      client.Get '/api/1/tests/1', (err, res) ->
        return done() if err?

        throw new Error 'Has not deleted resource'

  it 'should override default get route (GET)', (done) ->
    TestResource.routes.Add 'get', (req, res) ->
      res.status(200).send {message: 'Coucou'}

    client.Get '/api/1/tests', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.message, 'Coucou'
      done()
