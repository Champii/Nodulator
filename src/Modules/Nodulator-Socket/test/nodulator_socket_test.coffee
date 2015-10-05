_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require 'nodulator'

describe 'N', ->

  before (done) ->
    N.Reset done

  it 'should create server', (done) ->
    assert N.app
    assert N.server
    done()
