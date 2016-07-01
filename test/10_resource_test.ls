_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
expect = require 'chai' .expect

N = require '..'

Test = null

describe 'N Resource', (...) ->

  before (done) ->
    N.Reset ->
      Test := N \test
      # assert Test?
      done()

  it 'should not fetch first resource and display correct error', (done) ->
    Test.Fetch 1, (err, test) ->
      expect err        .to.be.a \object
      expect err.status .to.equal \not_found
      expect err.reason .to.equal '{"id":1}'
      expect err.source .to.equal \test
      expect test       .to.be.undefined
      done!

  it 'should add first resource', (done) ->
    Test.Create {test: 'test'}, (err, test) ->
      expect err       .to.be.null
      expect test      .to.be.a \object
      expect test.test .to.equal \test
      done!

  it 'should fetch first resource', (done) ->
    Test.Fetch 1, (err, test) ->
      expect err       .to.be.null
      expect test      .to.be.a \object
      expect test.id   .to.equal 1
      expect test.test .to.equal \test
      done!

  it 'should list all resources', (done) ->
    Test.List (err, tests) ->
      expect err          .to.be.null
      expect tests        .to.be.a \array
      expect tests.length .to.equal 1
      expect tests.0.test .to.equal \test
      done!

  it 'should save changed resource', (done) ->

    err, test <- Test.Fetch 1
    expect err .to.be.null

    test.test = 'test2'

    err, test2 <- test.Save!
    expect err .to.be.null

    err, test3 <- Test.Fetch 1
    expect err .to.be.null

    expect test3.test .to.equal \test2

    done!

  it 'should delete resource', (done) ->
    err, test <- Test.Fetch 1
    expect err .to.be.null

    err <- test.Delete!
    expect err .to.be.null

    err, test2 <- Test.Fetch 1
    expect err   .to.be.a \object
    expect test2 .to.be.undefined
    done!

  it 'should Create from an array of obj', (done) ->
    blob = [{field1: 1, field2: 1}
            {field1: 2, field2: 2}]

    Test.Create blob, (err, tests) ->
      expect err .to.be.null

      expect tests[0].field1 .to.equal 1
      expect tests[0].field2 .to.equal 1
      expect tests[1].field1 .to.equal 2
      expect tests[1].field2 .to.equal 2

      Test.List (err, tests) ->
        expect err .to.be.null

        expect tests[0].field1 .to.equal 1
        expect tests[0].field2 .to.equal 1
        expect tests[1].field1 .to.equal 2
        expect tests[1].field2 .to.equal 2

        done!

  it 'should Fetch from an obj', (done) ->
    Test.Fetch {field1: 1, field2: 1}, (err, tests) ->
      expect err .to.be.null

      expect tests.field1 .to.equal 1
      expect tests.field2 .to.equal 1

      done!

  it 'should Fetch from an array of id', (done) ->
    Test.Fetch [2, 3], (err, tests) ->
      expect err .to.be.null

      expect tests .to.be.a \array

      expect tests[0].field1 .to.equal 1
      expect tests[0].field2 .to.equal 1
      expect tests[1].field1 .to.equal 2
      expect tests[1].field2 .to.equal 2

      done!

  it 'should Fetch from an array of obj', (done) ->
    blob = [{field1: 1, field2: 1}
            {field1: 2, field2: 2}]

    Test.Fetch blob, (err, tests) ->
      expect err .to.be.null

      expect tests[0].field1 .to.equal 1
      expect tests[0].field2 .to.equal 1
      expect tests[1].field1 .to.equal 2
      expect tests[1].field2 .to.equal 2

      done!
