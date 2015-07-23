_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Nodulator = require '..'

test = it

describe 'Nodulator', ->

  before (done) ->
    Nodulator.Reset done

  test 'should create server', (done) ->
    assert Nodulator.app
    assert Nodulator.server
    done()
