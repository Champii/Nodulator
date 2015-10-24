_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

Tests = null

test = it

describe 'N Flip Done', ->

  before (done) ->
    N.Reset ->
      N.Config do
        flipDone: true

      Tests := N 'test'

      done()

  test 'It should have fliped done args', (done) ->
    Tests.Create test: 1, (test, err) ->
      assert test?
      assert not err?
      assert.equal test.test, 1
      done()

  test 'It should still return promise', (done) ->
    Tests.Create test: 1
      .Then (test) ->
        assert test?
        assert not err?
        assert.equal test.test, 1
        done()
