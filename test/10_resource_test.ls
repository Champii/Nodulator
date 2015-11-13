_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

test = it

Tests = null

describe 'N Resource', ->

  before (done) ->
    N.Reset ->
      Tests := N 'test'

      assert Tests?
      done()

  test 'should not fetch first resource', (done) ->
    Tests.Fetch 1, (err, test) ->
      return done! if err?

      throw new Error 'Fetched non-existant resource !'

  test 'should add first resource', (done) ->
    Tests.Create {test: 'test'}, (err, test) ->
      throw new Error 'Cannot Create test' if err?

      assert.equal test.test, 'test'

      done()

  test 'should fetch first resource', (done) ->
    Tests.Fetch 1, (err, test) ->
      throw new Error JSON.stringify err if err?

      assert.equal test.id, 1
      assert.equal test.test, 'test'

      done()

  test 'should list all resources', (done) ->
    Tests.List (err, tests) ->
      throw new Error 'Cannot List resources' if err?

      assert.equal tests.length, 1
      done()

  test 'should save changed resource', (done) ->

    err, test <- Tests.Fetch 1
    throw new Error err if err?

    test.test = 'test2'

    err, test2 <- test.Save!
    throw new Error err if err?

    err, test3 <- Tests.Fetch 1
    throw new Error err if err?

    assert.equal test3.test, 'test2'

    done()

  test 'should delete resource', (done) ->
    err, test <- Tests.Fetch 1, done
    throw new Error err if err?

    err <- test.Delete!
    throw new Error err if err?

    err, test2 <- Tests.Fetch 1
    return done() if err?

    throw new Error 'Has not deleted resource'

  test 'should Create from an array of obj', (done) ->
    blob = [{field1: 1, field2: 1}
            {field1: 2, field2: 2}]

    Tests.Create blob, (err, tests) ->
      throw new Error err if err?

      assert.equal tests[0].field1, 1
      assert.equal tests[0].field2, 1
      assert.equal tests[1].field1, 2
      assert.equal tests[1].field2, 2

      # console.log tests
      done()

  test 'should Fetch from an obj', (done) ->
    Tests.Fetch {field1: 1, field2: 1}, (err, tests) ->
      throw new Error err if err?

      assert.equal tests.field1, 1
      assert.equal tests.field2, 1

      # console.log tests
      done()

  test 'should Fetch from an array of id', (done) ->
    Tests.Fetch [2, 3], (err, tests) ->
      throw new Error err if err?

      throw new Error 'Result is not an array' if not Array.isArray tests

      # console.log err, tests

      assert.equal tests[0].field1, 1
      assert.equal tests[0].field2, 1
      assert.equal tests[1].field1, 2
      assert.equal tests[1].field2, 2

      done()

  test 'should Fetch from an array of obj', (done) ->
    blob = [{field1: 1, field2: 1}
            {field1: 2, field2: 2}]

    Tests.Fetch blob, (err, tests) ->
      throw new Error err if err?

      assert.equal tests[0].field1, 1
      assert.equal tests[0].field2, 1
      assert.equal tests[1].field1, 2
      assert.equal tests[1].field2, 2

      # console.log tests
      done()
