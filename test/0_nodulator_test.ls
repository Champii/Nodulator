_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Nodulator = require '..'

test = it

describe 'Nodulator', ->

  before (done) ->
    Nodulator.Reset done

  test 'should create resource', (done) ->
    Players = Nodulator.Resource \player
    assert Players
    done()
