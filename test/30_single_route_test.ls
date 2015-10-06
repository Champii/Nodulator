_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

N = require '..'

Tests = null

test = it

tests =  null

class TestRoute extends N.Route.SingleRoute

describe 'N Single Route', ->

  before (done) ->
    N.Reset ->
      config =
        schema:
          test:
            type: 'string'
            default: 'test'

      class TestRoute extends N.Route.SingleRoute
        resource: N 'test', config

      tests := new TestRoute

      done()

  test 'should fetch resource (GET)', (done) ->
    N.client.Get '/api/1/test', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal _(res.body).keys().length, 2
      done()

  test 'should save changed resource (PUT)', (done) ->
    err, {body} <- N.client.Get '/api/1/test'
    throw new Error err if err?

    body.test = 'test2'

    err, {body} <- N.client.Put '/api/1/test', body
    throw new Error err if err?

    err, {body} <- N.client.Get '/api/1/test'
    throw new Error err if err?

    assert body.test, 'test2'
    done()

  test 'should fetch resource (GET)', (done) ->
    N.client.Get '/api/1/test', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal _(res.body).keys().length, 2
      assert.equal res.body.test, 'test2'
      done()

  test 'should override default get route (GET)', (done) ->
    tests.Get -> {message: 'Coucou'}

    N.client.Get '/api/1/test', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.message, 'Coucou'
      done()
