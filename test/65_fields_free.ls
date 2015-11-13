_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

test = it

describe 'N Fields free', ->

  beforeEach (done) ->
    N.Reset done


  test 'should have id', (done) ->
    Tests = N \test
      ..Field \field \string

    Tests.Create!Then ->
      assert.equal it.id, 1
      done!

  test 'should set default field', (done) ->
    Tests = N \test
      ..Field \field \string .Default \lol

    Tests.Create!Then ->
      | it.field is \lol => done!
      | _                => done new Error 'Didnt set the default field'

  test 'should be optional', (done) ->
    Tests = N \test
      ..Field \field \string

    Tests.Create!Then ->
      | not it.field => done!
      | _            => done new Error 'Wasnt optional'

  test 'should be required', (done) ->
    Tests = N \test
      ..Field \field \string .Required!

    Tests.Create!
      .Then ->
        done new Error 'Wasnt required'
      .Catch -> done!
