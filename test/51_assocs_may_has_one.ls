_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'
expect = require 'chai' .expect

N = require '..'

Tests = null
Childs = null
News = null

describe 'N Associations MayHasOne', (...) ->

  beforeEach (done) ->
    N.Reset ->
      Childs := N \child

      Tests := N \test

      Tests.MayHasOne Childs

      done!

  it 'should create child without parent', (done) ->
    Childs
      .Create!
      .Then -> done!
      .Catch done

  it 'should create with id', (done) ->
    Childs
      .Create name: \child1 testId: Tests.Create name: \test
      .Then -> expect it.name .to.equal \child1
      .Then -> Tests.Fetch 1
      .Then ->
        expect it.name .to.equal \test
        expect it.child.name .to.equal \child1
        expect it.child.testId .to.equal 1
        done!

      .Catch -> done new Error JSON.stringify it

  it 'should create with Add', (done) ->
    Tests
      .Create name: \test
      .Add Childs.Create name: \child1
      .Then -> expect it.name .to.equal \test
      .Then -> Tests.Fetch 1
      .Then ->
        expect it.name .to.equal \test
        expect it.child.name .to.equal \child1
        expect it.child.testId .to.equal 1
        done!

      .Catch done

  it 'should create with Add reverse', (done) ->
    Childs
      .Create name: \child1
      .Add(Tests.Create name: \test)
      .Then -> expect it.name, \child1
      .Then -> Tests.Fetch 1
      .Then ->
        expect it.name .to.equal \test
        expect it.child.name .to.equal \child1
        expect it.child.testId .to.equal 1
        done!

      .Catch done

  it 'should remove child with promise', (done) ->
    Tests
      .Create name: \test
      .Add Childs.Create name: \child1
      .Then -> Tests.Fetch 1
      .Remove Childs.Fetch 1
      .Then ->
        expect it.child .to.equal undefined
        done!
      .Catch done

  it 'should remove child with instance', (done) ->
    Childs
      .Create name: \child1
      .Add Tests.Create name: \test
      .Then -> Tests.Fetch 1 .Remove it
      .Then ->
        expect it.child .to.equal undefined
        done!
      .Catch done
