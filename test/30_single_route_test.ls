_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

Nodulator = require '..'

Tests = null

test = it

class TestRoute extends Nodulator.Route.SingleRoute

describe 'Nodulator Single Route', ->

  before (done) ->
    Nodulator.Reset ->
      config =
        schema:
          test:
            type: 'string'
            default: 'test'

      Tests := Nodulator.Resource 'test', TestRoute, config

      done()

  test 'should fetch resource (GET)', (done) ->
    Nodulator.client.Get '/api/1/test', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal _(res.body).keys().length, 2
      done()

  test 'should save changed resource (PUT)', (done) ->
    err, {body} <- Nodulator.client.Get '/api/1/test'
    throw new Error err if err?

    body.test = 'test2'

    err, {body} <- Nodulator.client.Put '/api/1/test', body
    throw new Error err if err?

    err, {body} <- Nodulator.client.Get '/api/1/test'
    throw new Error err if err?

    assert body.test, 'test2'
    done()

  test 'should fetch resource (GET)', (done) ->
    Nodulator.client.Get '/api/1/test', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal _(res.body).keys().length, 2
      assert.equal res.body.test, 'test2'
      done()

  test 'should override default get route (GET)', (done) ->
    Tests.routes.Get (req, res) ->
      res.status(200).send {message: 'Coucou'}

    Nodulator.client.Get '/api/1/test', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.message, 'Coucou'
      done()
