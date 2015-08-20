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
 
      done()

  test 'should have Extend function', (done) ->
    assert ATests.Extend?
    done()

  test 'should have inherited methods', (done) ->
    class TestResource extends ATests.Extend 'test'

    assert TestResource::FetchByName?
    t = new TestResource {}
    assert t.FetchByName?
    done()

  test 'should have inherited in route', (done2) ->

    class Players extends Nodulator.Resource 'player'

      level: 1

      LevelUp: @_WrapPromise (done) ->
        @level++
        @Save done

      @ListUsernames = @_WrapPromise (done) ->
        # @List fmapA (-> __(it).pluck \username), done
        @List (err, list) ->
          return done err if err?

          done null, __(list).pluck \username

    class PlayerRoute extends Nodulator.Route.MultiRoute
      resource: Players

      Config: ->
        @Get \/usernames ~> @resource.ListUsernames!
        super()
        @Put '/:id/levelup' ~> it.instance.LevelUp!

    a = new PlayerRoute

    err <- Players.Create {test: 1, level: 1}
    throw new Error err if err?
    err, {body} <- Nodulator.client.Put \/api/1/players/1/levelup, {}
    throw new Error err if err?

    assert body.level, 2
    done2!

  test 'should have inherited in route 2', (done2) ->

    class PlayerRoute extends Nodulator.Route.MultiRoute

      Config: ->
        @Get \/usernames ~> @resource.ListUsernames!
        super()
        @Put '/:id/levelup' ~> it.instance.LevelUp!

    class Players extends Nodulator.Resource 'player', PlayerRoute

      level: 1

      LevelUp: @_WrapPromise (done) ->
        @level++
        @Save done

      @ListUsernames = @_WrapPromise (done) ->
        @List (err, list) ->
          return done err if err?

          done null, __(list).pluck \username


    err <- Players.Create {test: 1, level: 1}
    throw new Error err if err?
    err, {body} <- Nodulator.client.Put \/api/1/players/1/levelup, {}
    throw new Error err if err?

    assert body.level, 2
    done2!
    # console.log err, body
