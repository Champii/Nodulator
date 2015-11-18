_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

test = it

describe 'N Fields strict', ->

  beforeEach (done) ->
    N.Reset done

  test 'should have id', (done) ->
    Tests = N \test schema: \strict
      ..Field \field \string

    Tests.Create field: \lol .Then ->
      assert.equal it.id, 1
      done!
    .Catch -> done new Error JSON.stringify it

  test 'should set default field', (done) ->
    Tests = N \test schema: \strict
      ..Field \field \string .Default \lol

    Tests.Create!Then ->
      | it.field is \lol => done!
      | _                => done new Error 'Didnt set the default field'

  test 'should set default field with function', (done) ->
    Tests = N \test schema: \strict
      ..Field \field \string .Default -> \lol

    Tests.Create!Then ->
      | it.field is \lol => done!
      | _                => done new Error 'Didnt set the default field'

  test 'should be optional', (done) ->
    Tests = N \test schema: \strict
      ..Field \field \string .Optional!

    Tests.Create!Then ->
      | not it.field => done!
      | _            => done new Error 'Wasnt optional'

  test 'should be required', (done) ->
    Tests = N \test
      ..Field \field \string .Required!

    Tests.Create!
      .Then ->
        done new Error 'Wasnt required'
      .Catch ->
        Tests.Create field: \lol
          .Then -> done!
          .Catch ->
            done new Error it

  test 'should be virtual', (done) ->
    Tests = N \test schema: \strict
      ..Field \field \string .Virtual -> it.field2
      ..Field \field2 \string

    Tests.Create field2: \lol
      .Then ->
        assert.equal it.field, \lol
        done!
      .Catch ->
        done new Error it
