_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Nodulator = require '../lib/Nodulator'

Tests = null

describe 'Nodulator Flip Done', ->

  before (done) ->
    Nodulator.Reset ->
      Nodulator.Config
        flipDone: true

      Tests = Nodulator.Resource 'test'

      done()

  it 'It should have fliped done args', (done) ->
    Tests.Create test: 1, (test, err) ->
      assert test?
      assert not err?
      assert.equal test.test, 1
      done()

  it 'It should still return promise', (done) ->
    Tests.Create test: 1
    .then (test) ->
      assert test?
      assert not err?
      assert.equal test.test, 1
      done()
