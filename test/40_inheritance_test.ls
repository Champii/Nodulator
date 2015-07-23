_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

Nodulator = require '../lib/Nodulator'

client = null
ATests = null

test = it

class TestRoute extends Nodulator.Route

describe 'Nodulator Inheritance', ->

  before (done) ->
    Nodulator.Reset ->
      class AbTests extends Nodulator.Resource 'atest', {abstract: true}
        FetchByName: (name, done) ->
          @table.FindWhere '*', {name: name}, (err, blob) ~>
            throw new Error err if err?

            @resource._Deserialize blob, done

      assert AbTests?
      AbTests.Init()
      ATests := AbTests
      # client := new Client Nodulator.app
      done()

  test 'should have Extend function', (done) ->
    assert ATests.Extend
    done()

  test 'should have test1 inherited', (done) ->
    class TestResource extends ATests.Extend 'test', TestRoute

    assert TestResource.prototype.FetchByName
    done()
