_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

Tests = null

test = it

describe 'N Reactive Resource', ->

  beforeEach (done) ->
    N.Reset ->
      N.bus = new N.Bus
      done!

  test 'should watch for new resource', (done) ->
    Test = N \test

    Test.Watch \new ->
      assert.equal \lol it.field

      done!

    Test.Create field: \lol .Catch -> done new Error 'Error create'

  test 'should watch for updated resource', (done) ->
    Test = N \test

    Test.Watch \update ->
      assert.equal \lol2 it.field

      done!

    Test.Create field: \lol .Set field: \lol2 .Catch -> done new Error 'Error create'

  test 'should watch for deleted resource', (done) ->
    Test = N \test

    Test.Watch \delete ->
      assert.equal \lol it.field

      done!

    Test.Create field: \lol
      .Then -> Test.Delete field: \lol .Catch -> done new Error 'Error create'
