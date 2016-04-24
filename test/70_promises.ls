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

  test 'Chaining should return error FIXME', (done) ->
    Tests.Fetch 111
      .Catch -> done!
      .Set (.test++)
      .Set (.toto = \tata)
      .Then -> throw new Error it

  test 'Chaining Create and List should return promise', (done) ->
    Tmp = N \tmp
    Tmp
      .Create [
        * a: 1 b: 1
        * a: 2 b: 2]
      .Then -> Tmp.List!
      .Then ->
        assert.equal it.0.a, 1
        assert.equal it.0.b, 1
        assert.equal it.1.a, 2
        assert.equal it.1.b, 2
        done!
      .Catch -> done new Error it

  test 'Chaining should work with custom function', (done) ->
    class Tmp2 extends N \tmp2
      Test: -> @Set toto: \toto

    Tmp2.Create!Test!
      .Then ->
        assert.equal it.toto, \toto
        done!
      .Catch -> done new Error it
