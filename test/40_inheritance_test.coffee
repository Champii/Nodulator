_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

Nodulator = require '../lib/Nodulator'

client = null
ATests = null

class TestRoute extends Nodulator.Route

describe 'Nodulator Inheritance', ->

  before (done) ->
    Nodulator.Reset ->
      class ATests extends Nodulator.Resource 'atest', {abstract: true}
        FetchByName: (name, done) ->
          @table.FindWhere '*', {name: name}, (err, blob) =>
            throw new Error err if err?

            @resource._Deserialize blob, done

      assert ATests?
      ATests.Init()

      client = new Client Nodulator.app
      done()

  it 'should have Extend function', (done) ->
    assert ATests.Extend
    done()

  it 'should have test1 inherited', (done) ->
    class TestResource extends ATests.Extend 'test', TestRoute

    assert TestResource.prototype.FetchByName
    done()
