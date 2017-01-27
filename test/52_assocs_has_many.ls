_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
expect = require 'chai' .expect

N = require '..'

Tests = null
Childs = null
News = null

describe 'N Associations HasMany', (...) ->

  beforeEach (done) ->
    N.Reset ->
      Childs := N \child

      Tests := N \test

      Tests.HasMany Childs

      done!

  #TODO Test depth

  it 'should not create child without parent', (done) ->
    Childs.Create!
      .Then -> done new Error JSON.stringify it
      .Catch -> done!

  it 'should create with id', (done) ->
    Childs
      .Create name: \child1 testId: Tests.Create name: \test
      .Then -> expect it.name .to.equal \child1
      .Then -> Tests.Fetch 1
      .Then ->
        expect it.name .to.equal \test
        expect it.child.0.name .to.equal \child1
        expect it.child.0.testId .to.equal 1
        done!

      .Catch -> done new Error JSON.stringify it

  it 'should not remove child with promise', (done) ->
    Childs
      .Create name: \child1 testId: Tests.Create name: \test
      .Then -> Tests.Fetch 1
      .Remove Childs.Fetch 1
      .Then -> done new Error 'Has deleted ?!'
      .Catch -> done!

  it 'should not remove child', (done) ->
    Childs
      .Create name: \child1 testId: Tests.Create name: \test
      .Then -> Tests.Fetch 1 .Remove it
      .Then -> done new Error 'Has deleted ?!'
      .Catch -> done!
