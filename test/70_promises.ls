_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Nodulator = require '..'

Tests = null

test = it

describe 'Nodulator Promises', ->

  before (done) ->
    Nodulator.Reset ->
      Tests := Nodulator.Resource 'test'

      done()

  test 'Create should return promise', (done) ->
    Tests.Create test: 1
    .fail (err) -> throw new Error err
    .then (test) ->
      assert.equal test.test, 1
      done()


  test 'Fetch should return promise', (done) ->
    Tests.Fetch 1
    .fail (err) -> throw new Error err
    .then (test) ->
      assert.equal test.test, 1
      done()


  test 'List should return promise', (done) ->
    Tests.List()
    .fail (err) -> throw new Error err
    .then (tests) ->
      assert.equal tests[0].test, 1
      done()

  test 'Save should return promise', (done) ->
    Tests.Fetch 1
    .fail (err)  -> throw new Error err
    .then (test) ->
      test.test++
      test.Save()
    .then (test) ->
      assert.equal test.test, 2
      done()

  test 'Delete should return promise', (done) ->
    Tests.Delete 1
    .fail (err) -> throw new Error err
    .then ->
      done()
