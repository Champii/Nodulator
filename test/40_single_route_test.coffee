_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

Nodulator = require '../lib/Nodulator'

TestResource = null

class TestRoute extends Nodulator.Route.SingleRoute

describe 'Nodulator Single Route', ->

  before (done) ->
    Nodulator.Reset ->
      config =
        schema:
          test:
            type: 'string'
            default: 'test'

      TestResource = Nodulator.Resource 'test', TestRoute, config

      done()

  it 'should fetch resource (GET)', (done) ->
    Nodulator.client.Get '/api/1/test', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal _(res.body).keys().length, 2
      done()

  it 'should save changed resource (PUT)', (done) ->
    async.auto
      test: (done) ->
        Nodulator.client.Get '/api/1/test', (err, res) ->
          return done err if err?

          done null, res.body

      change: ['test', (done, results) ->
        results.test.test = 'test2'
        Nodulator.client.Put '/api/1/test', results.test, done]

    , (err, results) ->
      throw new Error err if err?

      Nodulator.client.Get '/api/1/test', (err, res) ->
        throw new Error err if err?

        assert res.body.test, 'test2'
        done()

  it 'should fetch resource (GET)', (done) ->
    Nodulator.client.Get '/api/1/test', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal _(res.body).keys().length, 2
      assert.equal res.body.test, 'test2'
      done()

  it 'should override default get route (GET)', (done) ->
    TestResource.routes.Get (req, res) ->
      res.status(200).send {message: 'Coucou'}

    Nodulator.client.Get '/api/1/test', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.message, 'Coucou'
      done()
