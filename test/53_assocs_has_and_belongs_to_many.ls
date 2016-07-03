_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
expect = require 'chai' .expect

N = require '..'

Item = null
Inventory = null
News = null

describe 'N Associations HasAndBelongsToMany', (...) ->

  beforeEach (done) ->
    N.Reset ->
      Inventory := N \inventory

      Item := N \item

      Item.HasAndBelongsToMany Inventory

      done!

  it 'should create inventory without parent', (done) ->
    Inventory.Create!
      .Then -> done!
      .Catch done

  it 'should create item without child', (done) ->
    Item.Create!
      .Then -> done!
      .Catch done

  it 'should create with Add', (done) ->
    Item
      .Create name: \item1
      .Add Inventory.Create name: \inv1
      .Then -> expect it.name .to.equal \item1
      .Then -> Item.Fetch 1
      .Then ->
        expect it.name .to.equal \item1
        expect it.Inventorys.0.name .to.equal \inv1
        done!

      .Catch done

  it 'should create with Add reverse', (done) ->
    Inventory
      .Create name: \inv1
      .Add Item.Create name: \item1
      .Then -> expect it.name .to.equal \inv1
      .Then -> Item.Fetch 1
      .Then ->
        expect it.name .to.equal \item1
        expect it.Inventorys.0.name .to.equal \inv1
        done!

      .Catch done

  it 'should remove child with promise', (done) ->
    Item
      .Create name: \item1
      .Add Inventory.Create name: \inv1
      .Then -> Item.Fetch 1
      .Remove Inventory.Fetch 1
      .Then ->
        expect it.Inventorys.length .to.equal 0
        done!

      .Catch done

  it 'should remove child with instance', (done) ->
    Inventory
      .Create name: \inv1
      .Add Item.Create name: \item1
      .Then -> Item.Fetch 1 .Remove it
      .Then ->
        expect it.Inventorys.length .to.equal 0
        done!
      .Catch done
