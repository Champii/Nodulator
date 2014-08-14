_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Modulator = require '../lib/Modulator'

request = null

describe 'Modulator Route', ->

  before (done) ->
    Modulator.Reset ->
      TestResource = Modulator.Resource 'test'
      assert TestResource?
      request = supertest Modulator.app
      done()

  it 'should add first resource (POST)', (done) ->
    request
      .post('/api/1/tests')
      .send({test: 'test'})
      .expect(200)
      .end done

  it 'should fetch first resource (GET)', (done) ->
    request
      .get('/api/1/tests/1')
      .expect(200)
      .end (err, req) ->
        throw new Error err if err?

        assert.equal req.body.id, 1
        assert.equal req.body.test, 'test'
        done()

  it 'should list all resources (GET)', (done) ->
    request
      .get('/api/1/tests')
      .expect(200)
      .end (err, req) ->
        throw new Error err if err?

        assert.equal req.body.length, 1
        done()

  it 'should save changed resource (PUT)', (done) ->
    async.auto
      test: (done) ->
        request
          .get('/api/1/tests/1')
          .expect(200)
          .end (err, res) ->
            return done err if err?

            done null, res.body
      change: ['test', (done, results) ->
        results.test.test = 'test2'
        request
          .put('/api/1/tests/1')
          .send(results.test)
          .expect(200)
          .end done]
    , (err, results) ->
      throw new Error err if err?

      request
        .get('/api/1/tests/1')
        .expect(200)
        .end (err, res) ->
          throw new Error err if err?

          assert res.body.test, 'test2'
          done()

  it 'should delete resource (DELETE)', (done) ->
    request
      .delete('/api/1/tests/1')
      .expect(200)
      .end (err, res) ->
        throw new Error err if err?

        request
          .get('/api/1/tests/1')
          .expect(200)
          .end (err, res) ->
            return done() if err?

            throw new Error 'Has not deleted resource'
