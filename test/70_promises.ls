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

###
###

  test 'Create should return error', (done) ->
    Tests.Field \test \int .Required!
    Tests.Create!
      .Then (test) -> throw new Error 'Wtf'
      .Catch -> done!

  test 'Fetch should return error', (done) ->
    Tests.Fetch 2
      .Then (test) -> throw new Error 'Wtf'
      .Catch -> done!

  test 'List should return error', (done) ->
    Tests.List()
      .Then (test) -> throw new Error 'Wtf'
      .Catch -> done!

  test 'Delete should return error', (done) ->
    Tests.Delete 2
      .Then (test) -> throw new Error 'Wtf'
      .Catch -> done!

###
###

  test 'Chaining should return promise', (done) ->
    Tests.Create test: 1
      .Set (.test++)
      .Set (.toto = \tata)
      .Log!
      .Then -> done!
      .Catch -> throw new Error it

  test 'Chaining should return error', (done) ->
    Tests.Fetch 111
      .Set (.test++)
      .Set (.toto = \tata)
      .Log!
      .Catch -> done!
      .Then -> throw new Error it
