_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
expect = require 'chai' .expect

tests = null

N = require '..'

describe 'N Multi Route', (...) ->

  before (done) ->
    N.Reset ->

      class TestRoute extends N.Route.Collection
        resource: N \tests

      tests := new TestRoute
      done!


  it 'should add first resource (POST)', (done) ->
    N.client.Post '/api/1/tests', {test: 'test'}, (err, res) ->
      expect err .to.be.null

      expect res.body.id .to.equal 1
      expect res.body.test .to.equal 'test'
      done!

  it 'should fetch first resource (GET)', (done) ->
    N.client.Get '/api/1/tests/1', (err, res) ->
      expect err .to.be.null

      expect res.body.id .to.equal 1
      expect res.body.test .to.equal 'test'
      done!

  it 'should list all resources (GET)', (done) ->
    N.client.Get '/api/1/tests', (err, res) ->
      expect err .to.be.null

      expect res.body.length .to.equal 1
      done!

  it 'should save changed resource (PUT)', (done) ->
    newObj =
      test: 'test2'

    err, {body} <- N.client.Put '/api/1/tests/1', newObj
    expect err .to.be.null


    err, {body} <- N.client.Get '/api/1/tests/1'
    expect err .to.be.null

    expect body.test .to.equal 'test2'
    done!

  it 'should delete resource (DELETE)', (done) ->
    N.client.Delete '/api/1/tests/1', (err, res) ->
      expect err .to.be.null

      N.client.Get '/api/1/tests/1', (err, res) ->
        expect err .to.be.not.null
        done!

  it 'should override default get route (GET)', (done) ->
    tests.Get -> {message: 'Coucou'}

    N.client.Get '/api/1/tests', (err, res) ->
      expect err .to.be.null

      expect res.body.message .to.equal 'Coucou'
      done!
