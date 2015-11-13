_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

Tests = null
Childs = null
News = null

test = it

describe 'N Associations HasMany', ->

  beforeEach (done) ->
    N.Reset ->
      Childs := N \child

      Tests := N \test

      Tests.HasMany Childs

      done!

  test 'should not create child without parent', (done) ->
    Childs.Create!
      .Then -> done new Error JSON.stringify it
      .Catch -> done!

  test 'should create with id', (done) ->
    Childs.Create name: \child1 testId: Tests.Create name: \test
      .Then -> assert.equal it.name, \child1
      .Then ->
        Tests.Fetch 1
          .Then ->
            assert.equal it.name, \test
            assert.equal it.Childs.0.name, \child1
            assert.equal it.Childs.0.testId, 1
            done!

        .Catch -> done new Error JSON.stringify it

  test 'should not remove child with promise', (done) ->
    Childs.Create name: \child1 testId: Tests.Create name: \test
      .Then ->
        Tests.Fetch 1 .Remove Childs.Fetch 1
          .Then -> done new Error 'Has deleted ?!'
          .Catch -> done!

  test 'should not remove child', (done) ->
    Childs.Create name: \child1 testId: Tests.Create name: \test
      .Then ->
        Tests.Fetch 1 .Remove it
          .Then -> done new Error 'Has deleted ?!'
          .Catch -> done!
