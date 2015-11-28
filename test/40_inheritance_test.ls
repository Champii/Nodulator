_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
Client = require './common/client'

N = require '..'

client = null
ATests = null

test = it

TestRoute = null

describe 'N Inheritance', ->

  before (done) ->
    N.Reset ->
      class AbTests extends N 'atest', {abstract: true}

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

    class Players extends N 'player'

      level: 1

      LevelUp: @_WrapPromise (done) ->
        @level++
        @Save done

      @ListUsernames = @_WrapPromise (done) ->
        @List (err, list) ->
          return done err if err?

          done null, __(list).pluck \username

    class PlayerRoute extends N.Route.MultiRoute
      resource: Players

      Config: ->
        @Get \/usernames ~> @resource.ListUsernames!
        super()
        @Put '/:id/levelup' ~> it.instance.LevelUp!

    a = new PlayerRoute

    err <- Players.Create {test: 1, level: 1}
    throw new Error err if err?
    err, {body} <- N.client.Put \/api/1/players/1/levelup, {}
    throw new Error err if err?

    assert body.level, 2
    done2!

  test 'should have inherited in route 2', (done2) ->

    class PlayerRoute extends N.Route.MultiRoute

      Config: ->
        @Get \/usernames ~> @resource.ListUsernames!
        super()
        @Put '/:id/levelup' ~> it.instance.LevelUp!

    class Players extends N 'player2', PlayerRoute

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
    err, {body} <- N.client.Put \/api/1/players/1/levelup, {}
    throw new Error err if err?

    assert body.level, 2
    done2!
    # console.log err, body

  test 'should have inherited fields', (done) ->
    P = N \p

    P.Field \a \int .Default 0

    C = P.Extend \c

    C.Create!
      .Then -> assert.equal it.a, 0
      .Then -> done!
      .Catch done

  test 'should not have inherited fields', (done) ->
    P2 = N \p2

    P2.Field \a \int .Default 0

    C2 = P2.Extend \c2

    C2.Field \b \int .Default 1

    P2.Create!
      .Then -> assert.equal it.a, 0
      .Then -> assert.equal it.b, undefined
      .Then -> done!
      .Catch done
