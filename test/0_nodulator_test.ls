_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

test = it

describe 'N', ->

  before (done) ->
    N.Reset done

  test 'should create resource', (done) ->
    Players = N.Resource \player
    assert Players
    done()
