_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'
expect = require 'chai' .expect
N = require '..'

describe 'N Route', (...) ->

  before (done) ->
    N.Reset ->

      class TestRoute extends N.Route
        resource: N \tests

        Config: ->
          super()
          @Get -> {message: 'Coucou'}

      new TestRoute
      done!

  it 'should get resource', (done) ->
    N.client.Get '/api/1/tests', (err, res) ->
      expect err .to.be.null

      expect res.body.message .to.equal 'Coucou'
      done!
