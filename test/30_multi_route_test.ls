_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

Tests = null
tests = null
test = it

describe 'N Multi Route', ->

  before (done) ->
    N.Reset ->

      class TestRoute extends N.Route.MultiRoute
        resource: N 'test'

      tests := new TestRoute

      done()


  test 'should add first resource (POST)', (done) ->
    N.client.Post '/api/1/tests', {test: 'test'}, (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal res.body.test, 'test'
      done()

  test 'should fetch first resource (GET)', (done) ->
    N.client.Get '/api/1/tests/1', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.id, 1
      assert.equal res.body.test, 'test'
      done()

  test 'should list all resources (GET)', (done) ->
    N.client.Get '/api/1/tests', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.length, 1
      done()

  test 'should save changed resource (PUT)', (done) ->
    err, {body} <- N.client.Get '/api/1/tests/1'
    throw new Error err if err?

    body.test = 'test2'

    err, {body} <- N.client.Put '/api/1/tests/1', body
    throw new Error err if err?


    err, {body} <- N.client.Get '/api/1/tests/1'
    throw new Error err if err?

    assert body.test, 'test2'
    done()

  test 'should delete resource (DELETE)', (done) ->
    N.client.Delete '/api/1/tests/1', (err, res) ->
      throw new Error err if err?

      N.client.Get '/api/1/tests/1', (err, res) ->
        return done() if err?

        console.log 'Found', res.body
        throw new Error 'Has not deleted resource'

  test 'should override default get route (GET)', (done) ->
    tests.Get -> {message: 'Coucou'}

    N.client.Get '/api/1/tests', (err, res) ->
      throw new Error err if err?

      assert.equal res.body.message, 'Coucou'
      done()
