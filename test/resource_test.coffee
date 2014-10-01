_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Modulator = require '../lib/Modulator'

TestResource = null

describe 'Modulator Resource', ->

  before (done) ->
    Modulator.Reset ->
      TestResource = Modulator.Resource 'test'
      assert TestResource?
      done()

  it 'should add first resource', (done) ->
    TestResource.Deserialize {test: 'test'}, (err, test) ->
      throw new Error 'Cannot Deserialize test' if err?

      test.Save (err) ->
        throw new Error 'Cannot Save test' if err?

        done()

  it 'should fetch first resource', (done) ->
    TestResource.Fetch 1, (err, test) ->
      throw new Error 'Cannot Fetch first resource' if err?

      assert.equal test.id, 1
      assert.equal test.test, 'test'

      done()

  it 'should list all resources', (done) ->
    TestResource.List (err, tests) ->
      throw new Error 'Cannot List resources' if err?

      assert.equal tests.length, 1
      done()

  it 'should save changed resource', (done) ->
    async.auto
      test: (done) ->
        TestResource.Fetch 1, done
      change: ['test', (done, results) ->
        results.test.test = 'test2'
        results.test.Save done]
      test2: ['change', (done, results) ->
        TestResource.Fetch 1, done]
      , (err, results) ->
        throw new Error err if err?

        assert.equal results.test2.test, 'test2'
        done()

  it 'should delete resource', (done) ->
    async.auto
      test: (done) ->
        TestResource.Fetch 1, done
      del: ['test', (done, results) ->
        results.test.Delete done]
    , (err, results) ->
      throw new Error err if err?

      TestResource.Fetch 1, (err, test) ->
        return done() if err?

        throw new Error 'Has not deleted resource'


