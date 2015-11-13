_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

Tests = null
Childs = null
News = null

test = it

describe 'N Associations MayHasOne', ->

  beforeEach (done) ->
    N.Reset ->
      Childs := N \child

      Tests := N \test

      Tests.MayHasOne Childs

      done!

  test 'should create child without parent', (done) ->
    Childs.Create!
      .Then -> done!
      .Catch -> done new Error it

  test 'should create with id', (done) ->
    Childs.Create name: \child1 testId: Tests.Create name: \test
      .Then -> assert.equal it.name, \child1
      .Then ->
        Tests.Fetch 1
          .Then ->
            assert.equal it.name, \test
            assert.equal it.Child.name, \child1
            assert.equal it.Child.testId, 1
            done!

      .Catch -> done new Error JSON.stringify it

  test 'should create with Add', (done) ->
    Tests.Create name: \test .Add Childs.Create name: \child1
      .Then -> assert.equal it.name, \test
      .Then ->
        Tests.Fetch 1
          .Then ->
            assert.equal it.name, \test
            assert.equal it.Child.name, \child1
            assert.equal it.Child.testId, 1
            done!

          .Catch -> done new Error it
      .Catch -> done new Error it

  test 'should create with Add reverse', (done) ->
    Childs.Create name: \child1 .Add Tests.Create name: \test
      .Then ->
        assert.equal it.name, \child1
      .Then ->
        Tests.Fetch 1
          .Then ->
            assert.equal it.name, \test
            assert.equal it.Child.name, \child1
            assert.equal it.Child.testId, 1
            done!

      .Catch -> done new Error it

  test 'should remove child with promise', (done) ->
    Tests.Create name: \test .Add Childs.Create name: \child1
      .Then ->
        Tests.Fetch 1 .Remove Childs.Fetch 1
          .Then ->
            assert.equal it.Child, undefined
            done!
      .Catch -> done new Error it

  test 'should remove child with instance', (done) ->
    Childs.Create name: \child1 .Add Tests.Create name: \test
      .Then ->
        Tests.Fetch 1 .Remove it
          .Then ->
            assert.equal it.Child, undefined
            done!
      .Catch -> done new Error it
