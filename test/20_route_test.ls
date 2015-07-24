_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

Nodulator = require '../lib/Nodulator'

client = null
Tests = null

test = it

describe 'Nodulator Route', ->

  before (done) ->
    Nodulator.Reset ->

      class TestRoute extends Nodulator.Route
        resource: Nodulator.Resource 'test'
        
        Config: ->
          super()
          @Get -> {message: 'Coucou'}

      new TestRoute
      done()

  test 'should get resource', (done) ->
    Nodulator.client.Get '/api/1/tests', (err, res) ->
      assert.equal res.body.message, 'Coucou'
      done()
