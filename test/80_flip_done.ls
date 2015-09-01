_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Nodulator = require '..'

Tests = null

test = it

describe 'Nodulator Flip Done', ->

  before (done) ->
    Nodulator.Reset ->
      Nodulator.Config do
        flipDone: true

      Tests := Nodulator.Resource 'test'

      done()

  test 'It should have fliped done args', (done) ->
    Tests.Create test: 1, (test, err) ->
      assert test?
      assert not err?
      assert.equal test.test, 1
      done()

  test 'It should still return promise', (done) ->
    Tests.Create test: 1
    .then (test) ->
      assert test?
      assert not err?
      assert.equal test.test, 1
      done()
