_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Nodulator = require '..'

Tests = null
tests = null
test = it

describe 'Nodulator Multi Route', ->

  before (done) ->
    Nodulator.Reset ->

      class TestRoute extends Nodulator.Route.MultiRoute
        resource: Nodulator.Resource 'test'

      tests := new TestRoute

      done()


  test 'should add first resource (POST)', (done) ->
    Nodulator.client.Post '/api/1/tests', {test: 'test'}, (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal res.body.test, 'test'
      done()

  test 'should fetch first resource (GET)', (done) ->
    Nodulator.client.Get '/api/1/tests/1', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal res.body.test, 'test'
      done()

  test 'should list all resources (GET)', (done) ->
    Nodulator.client.Get '/api/1/tests', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.length, 1
      done()

  test 'should save changed resource (PUT)', (done) ->
    err, {body} <- Nodulator.client.Get '/api/1/tests/1'
    throw new Error err if err?

    body.test = 'test2'

    err, {body} <- Nodulator.client.Put '/api/1/tests/1', body
    throw new Error err if err?


    err, {body} <- Nodulator.client.Get '/api/1/tests/1'
    throw new Error err if err?

    assert body.test, 'test2'
    done()

  test 'should delete resource (DELETE)', (done) ->
    Nodulator.client.Delete '/api/1/tests/1', (err, res) ->
      throw new Error err if err?

      Nodulator.client.Get '/api/1/tests/1', (err, res) ->
        return done() if err?

        console.log 'Found', res
        throw new Error 'Has not deleted resource'

  test 'should override default get route (GET)', (done) ->
    tests.Get -> {message: 'Coucou'}

    Nodulator.client.Get '/api/1/tests', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.message, 'Coucou'
      done()
