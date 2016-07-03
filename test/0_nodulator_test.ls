_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
expect = require 'chai' .expect

N = require '..'

describe 'N', (...) ->

  before (done) ->
    N.Reset done

  #TODO: test config process

  it 'should be correctly defined', (done) ->
    expect N             .to.be.a \function
    expect N.Init        .to.be.a \function
    expect N.Resource    .to.be.a \function
    expect N.Config      .to.be.a \function
    expect N.Reset       .to.be.a \function
    expect N.PostConfig  .to.be.a \function
    done!


  it 'should create a resource', (done) ->
    Players = N \player
    expect Players                     .to.be.a \function
    expect Players.Create              .to.be.a \function
    expect Players.Fetch               .to.be.a \function
    expect Players.Delete              .to.be.a \function
    expect Players.Watch               .to.be.a \function
    expect Players.HasOne              .to.be.a \function
    expect Players.MayHasOne           .to.be.a \function
    expect Players.HasMany             .to.be.a \function
    expect Players.MayHasMany          .to.be.a \function
    expect Players.HasAndBelongsToMany .to.be.a \function
    expect Players.BelongsTo           .to.be.a \function
    expect Players.MayBelongsTo        .to.be.a \function
    done!

  it 'should create an instance', (done) ->
    Players = N \player
    Players
      .Create!
      .Then ->
        expect it        .to.be.a \object
        expect it.Set    .to.be.a \function
        expect it.Save   .to.be.a \function
        expect it.Delete .to.be.a \function
        expect it.Watch  .to.be.a \function
        expect it.Add    .to.be.a \function
        expect it.Remove .to.be.a \function
        done!
