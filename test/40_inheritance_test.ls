_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
expect = require 'chai' .expect
Client = require './common/client'

N = require '..'

client = null
ATests = null

TestRoute = null

describe 'N Inheritance', (...) ->

  before (done) ->
    N.Reset ->
      class AbTests extends N 'atest', {abstract: true}

        @StaticMethod = -> 1

        FetchByName: (name, done) ->
          @table.FindWhere '*', {name: name}, (err, blob) ~>
            expect err .to.be.null

            @resource._Deserialize blob, done

      expect AbTests .to.be.not.null
      ATests := AbTests
      ATests.Init()

      done!

  it 'should have Extend function', (done) ->
    expect ATests.Extend .to.be.a \function
    done!

  it 'should have inherited methods', (done) ->
    class TestResource extends ATests.Extend 'test'

    expect TestResource::FetchByName .to.be.a \function

    expect TestResource.StaticMethod .to.be.a \function
    expect TestResource.StaticMethod! .to.be.equal 1

    t = new TestResource {}
    expect t.FetchByName .to.be.a \function
    done!

  it 'should have inherited in route', (done2) ->

    class Players extends N \players

      LevelUp: ->
        @Set ~> @level++

      @ListUsernames = @_WrapPromise (done) ->
        @List (err, list) ->
          return done err if err?

          done null, __(list).pluck \username

    class PlayerRoute extends N.Route.Collection
      resource: Players

      Config: ->
        @Get \/usernames ~> @resource.ListUsernames!
        super()
        @Put '/:id/levelup' ~> it.instance.LevelUp!

    a = new PlayerRoute

    err <- Players.Create {test: 1, level: 1}
    expect err .to.be.null

    err, {body} <- N.client.Put \/api/1/players/1/levelup, {}
    expect err .to.be.null

    expect body.level .to.equal 2
    done2!

  it 'should have inherited in route 2', (done2) ->

    class PlayerRoute extends N.Route.Collection

      Config: ->
        @Get \/usernames ~> @resource.ListUsernames!
        super()
        @Put '/:id/levelup' ~> it.instance.LevelUp!

    class Players extends N 'p', PlayerRoute

      LevelUp: ->
        @Set ~> @level++

      @ListUsernames = @_WrapPromise (done) ->
        @List (err, list) ->
          return done err if err?

          done null, __(list).pluck \username


    err <- Players.Create {test: 1, level: 1}
    expect err .to.be.null

    err, {body} <- N.client.Put \/api/1/p/1/levelup, {}
    expect err .to.be.null

    expect body.level .to.equal 2
    done2!
    # console.log err, body

  it 'should have inherited fields', (done) ->
    P = N \ps

    P.Field \a \int .Default 0

    C = P.Extend \cs

    C.Create!
      .Then -> expect it.a .to.equal 0
      .Then -> done!
      .Catch done

  it 'should not have inherited fields', (done) ->
    P2 = N \p2s

    P2.Field \a \int .Default 0

    C2 = P2.Extend \c2s

    C2.Field \b \int .Default 1

    P2.Create!
      .Then -> expect it.a .to.equal 0
      .Then -> expect it.b .to.be.undefined
      .Then -> done!
      .Catch done

  it 'should have every inherited static methods', (done) ->
    P3 = N \p3
    C3 = P3.Extend \c3

    expect C3.Watch .to.be.not.null

    C3.Watch \new -> done!

    C3.Create!
