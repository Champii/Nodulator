_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

Item = null
Inventory = null
News = null

test = it

describe 'N Associations HasAndBelongsToMany', ->

  beforeEach (done) ->
    N.Reset ->
      Inventory := N \inventory

      Item := N \item

      Item.HasAndBelongsToMany Inventory

      done!

  test 'should create inventory without parent', (done) ->
    Inventory.Create!
      .Then -> done!
      .Catch -> done new Error it

  test 'should create item without parent', (done) ->
    Item.Create!
      .Then -> done!
      .Catch -> done new Error it

  test 'should create with Add', (done) ->
    Item.Create name: \item1 .Add Inventory.Create name: \inv1
      .Then -> assert.equal it.name, \item1
      .Then ->
        Item.Fetch 1
          .Then ->
            assert.equal it.name, \item1
            assert.equal it.Inventorys.0.name, \inv1
            done!

          .Catch -> done new Error it
      .Catch -> done new Error it

  test 'should create with Add reverse', (done) ->
    Inventory.Create name: \inv1 .Add(Item.Create name: \item1)
      .Then ->
        assert.equal it.name, \inv1
      .Then ->
        Item.Fetch 1
          .Then ->
            assert.equal it.name, \item1
            assert.equal it.Inventorys.0.name, \inv1
            done!

      .Catch -> done new Error it

  test 'should remove child with promise', (done) ->
    Item.Create name: \item1 .Add Inventory.Create name: \inv1
      .Then ->
        Item.Fetch 1 .Remove Inventory.Fetch 1
          .Then ->
            assert.equal it.Inventorys.length, 0
            done!
      .Catch -> done new Error it

  test 'should remove child with instance', (done) ->
    Inventory.Create name: \inv1 .Add Item.Create name: \item1
      .Then ->
        Item.Fetch 1 .Remove it
          .Then ->
            assert.equal it.Inventorys.length, 0
            done!
      .Catch -> done new Error it
