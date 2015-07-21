_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Nodulator = require '../lib/Nodulator'

Tests = null

describe 'Nodulator Resource', ->

  before (done) ->
    Nodulator.Reset ->
      Tests = Nodulator.Resource 'test'
      assert Tests?
      done()

  it 'should add first resource', (done) ->
    Tests._Deserialize {test: 'test'}, (err, test) ->
      throw new Error 'Cannot _Deserialize test' if err?

      test.Save (err) ->
        throw new Error 'Cannot Save test' if err?

        done()

  it 'should fetch first resource', (done) ->
    Tests.Fetch 1, (err, test) ->
      throw new Error 'Cannot Fetch first resource' if err?

      assert.equal test.id, 1
      assert.equal test.test, 'test'

      done()

  it 'should list all resources', (done) ->
    Tests.List (err, tests) ->
      throw new Error 'Cannot List resources' if err?

      assert.equal tests.length, 1
      done()

  it 'should save changed resource', (done) ->
    async.auto
      test: (done) ->
        Tests.Fetch 1, done
      change: ['test', (done, results) ->
        results.test.test = 'test2'
        results.test.Save done]
      test2: ['change', (done, results) ->
        Tests.Fetch 1, done]
    , (err, results) ->
      throw new Error err if err?

      assert.equal results.test2.test, 'test2'
      done()

  it 'should delete resource', (done) ->
    async.auto
      test: (done) ->
        Tests.Fetch 1, done
      del: ['test', (done, results) ->
        results.test.Delete done]
    , (err, results) ->
      throw new Error err if err?

      Tests.Fetch 1, (err, test) ->
        return done() if err?

        throw new Error 'Has not deleted resource'

  it 'sould Create from an array of obj', (done) ->
    blob = [{field1: 1, field2: 1}
            {field1: 2, field2: 2}]

    Tests.Create blob, (err, tests) ->
      throw new Error err if err?

      assert.equal tests[0].field1, 1
      assert.equal tests[0].field2, 1
      assert.equal tests[1].field1, 2
      assert.equal tests[1].field2, 2

      done()

  it 'sould Fetch from an array of id', (done) ->
    Tests.Fetch [1, 2], (err, tests) ->
      console.error err if err?
      throw new Error err if err?

      throw new Error 'Result is not an array' if not Array.isArray tests

      assert.equal tests[0].field1, 1
      assert.equal tests[0].field2, 1
      assert.equal tests[1].field1, 2
      assert.equal tests[1].field2, 2

      done()
