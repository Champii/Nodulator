_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

Nodulator = require '../lib/Nodulator'

client = null
TestResource = null

class TestRoute extends Nodulator.Route
  Config: ->
    super()
    @Get (req, res) ->
      res.status(200).send {message: 'Coucou'}

describe 'Nodulator Route', ->

  before (done) ->
    Nodulator.Reset ->
      TestResource = Nodulator.Resource 'test', TestRoute

      done()

  it 'should get resource', (done) ->
    Nodulator.client.Get '/api/1/tests', (err, res) ->
      assert.equal res.body.message, 'Coucou'
      done()
