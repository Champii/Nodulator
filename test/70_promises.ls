_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

Tests = null

test = it

describe 'N Promises', ->

  before (done) ->
    N.Reset ->
      Tests := N 'test'

      done()

  test 'Create should return promise', (done) ->
    Tests.Create test: 1
    .Then (test) ->
      assert.equal test.test, 1
      done()
    .Catch (err) -> throw new Error err

  test 'Fetch should return promise', (done) ->
    Tests.Fetch 1
    .Then (test) ->
      assert.equal test.test, 1
      done()
    .Catch (err) -> throw new Error err

  test 'List should return promise', (done) ->
    Tests.List()
    .Then (tests) ->
      assert.equal tests[0].test, 1
      done()
    .Catch (err) -> throw new Error err

  test 'Save should return promise', (done) ->
    Tests.Fetch 1
    .Then (test) ->
      test.test++
      test.Save()
    .Then (test) ->
      assert.equal test.test, 2
      done()
    .Catch (err)  -> throw new Error err

  test 'Delete should return promise', (done) ->
    Tests.Delete 1
    .Then ->
      done()
    .Catch (err) -> throw new Error err
