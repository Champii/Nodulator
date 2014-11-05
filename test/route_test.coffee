_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

Modulator = require '../'

client = null
TestResource = null

class TestRoute extends Modulator.Route
  Config: ->
    super()
    @Add 'get', '', (req, res) ->
      res.status(200).send {message: 'Coucou'}

describe 'Modulator Route', ->

  before (done) ->
    Modulator.Reset ->
      TestResource = Modulator.Resource 'test', TestRoute
      assert TestResource?
      TestResource.Init()

      client = new Client Modulator.app
      done()

  it 'should get resource', (done) ->
    client.Get '/api/1/tests', (err, res) ->
      assert.equal res.body.message, 'Coucou'
      done()
