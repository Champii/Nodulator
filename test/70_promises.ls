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
    .Catch (err) -> throw new Error err
    .Then (test) ->
      assert.equal test.test, 1
      done()


  test 'Fetch should return promise', (done) ->
    Tests.Fetch 1
    .Catch (err) -> throw new Error err
    .Then (test) ->
      assert.equal test.test, 1
      done()


  test 'List should return promise', (done) ->
    Tests.List()
    .Catch (err) -> throw new Error err
    .Then (tests) ->
      assert.equal tests[0].test, 1
      done()

  test 'Save should return promise', (done) ->
    Tests.Fetch 1
    .Catch (err)  -> throw new Error err
    .Then (test) ->
      test.test++
      test.Save()
    .Then (test) ->
      assert.equal test.test, 2
      done()

  test 'Delete should return promise', (done) ->
    Tests.Delete 1
    .Catch (err) -> throw new Error err
    .Then ->
      done()
