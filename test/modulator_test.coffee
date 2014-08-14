_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Modulator = require '../lib/Modulator'

describe 'Modulator', ->

  before (done) ->
    Modulator.Reset done

  it 'should create server', (done) ->
    assert Modulator.app
    assert Modulator.server
    done()
