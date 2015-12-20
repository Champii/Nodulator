_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

N = require '..'

client = null
Tests = null

test = it

describe 'N Route', ->

  before (done) ->
    N.Reset ->

      class TestRoute extends N.Route
        resource: N \tests

        Config: ->
          super()
          @Get -> {message: 'Coucou'}

      new TestRoute
      N._ListEndpoints console.log
      done()

  test 'should get resource', (done) ->
    N.client.Get '/api/1/tests', (err, res) ->
      throw err if err?

      assert.equal res.body.message, 'Coucou'
      done()
