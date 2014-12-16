_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Nodulator = require '../lib/Nodulator'

describe 'Nodulator', ->

  before (done) ->
    Nodulator.Reset done

  it 'should create server', (done) ->
    assert Nodulator.app
    assert Nodulator.server
    done()
