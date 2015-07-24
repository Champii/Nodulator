_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

Nodulator = require '../lib/Nodulator'

client = null
ATests = null

test = it

TestRoute = null

describe 'Nodulator Inheritance', ->

  before (done) ->
    Nodulator.Reset ->
      class AbTests extends Nodulator.Resource 'atest', {abstract: true}
        FetchByName: (name, done) ->
          @table.FindWhere '*', {name: name}, (err, blob) ~>
            throw new Error err if err?

            @resource._Deserialize blob, done

      assert AbTests?
      ATests := AbTests
      ATests.Init()
      #
      # class _TestRoute extends Nodulator.Route
      #   resource: ATests
      #
      # new _TestRoute
      #

      # TestRoute := _TestRoute/

      # AbTests.Init()
      # client := new Client Nodulator.app
      done()

  test 'should have Extend function', (done) ->
    assert ATests.Extend?
    done()

  test 'should have test1 inherited', (done) ->
    class TestResource extends ATests.Extend 'test'

    # TestResource.Init()
    assert TestResource.prototype.FetchByName?
    t = new TestResource {}
    assert t.FetchByName?
    done()

  test 'should have inherited in route', (done2) ->

    class Players extends Nodulator.Resource 'player'

      level: 1

      LevelUp: @_WrapPromise (done) ->
        @level++
        @Save (err) ->
          done2 err

      @ListUsernames = @_WrapPromise (done) ->
        # @List fmapA (-> __(it).pluck \username), done
        @List (err, list) ->
          return done err if err?

          done null, __(list).pluck \username

    class PlayerRoute extends Nodulator.Route.MultiRoute
      resource: Players

      Config: ->
        # console.log 'Test Config'
        @Get '/usernames' ~> @resource.ListUsernames!
        super()
        @Put '/:id/levelup' ~>
          # console.log 'LEVELUP???', @resource, it.instance.LevelUp
          it.instance.LevelUp!


    a = new PlayerRoute

    <- Players.Create {test: 1}
    err, {body} <- Nodulator.client.Put \/api/1/players/1/levelup, {}
    throw new Error err if err?

    # console.log err, body
