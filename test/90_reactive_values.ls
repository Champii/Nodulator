_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Nodulator = require '../lib/Nodulator'

Tests = null

test = it

describe 'Nodulator Reactive value', ->

  before (done) ->
    Nodulator.Reset ->
      Tests := Nodulator.Resource 'test'
      Tests.Create [
        {test: 1}
        {test: 1}
        {test: 1}
        {test: 1}
        {test: 1}
        {test: 2}]
      .then ->
        assert it.length, 6
        done()

  test 'should be watching', (done) ->
    assert.equal Nodulator.Watch.active, false
    Nodulator.Watch ->
      assert.equal Nodulator.Watch.active, true

    assert.equal Nodulator.Watch.active, false
    done()

  test 'should return computation', (done) ->
    handler = Nodulator.Watch ->

    if not handler?
      throw new Error 'No handler'

    done()

  test 'should stop computation', (done) ->
    times = 0
    handler = Nodulator.Watch ->
      times++
      if times >= 2
        done()
      Tests.Fetch 1

    Tests.Fetch 1
    .then (test) ->
      test.test++
      test.Save()

    handler.Stop()

    Tests.Fetch 1
    .then (test) ->
      test.test++
      test.Save ->
        done()

  test 'should watch changes for Fetch', (done) ->
    times = 0
    # console.log
    handler = Nodulator.Watch ->
      times++
      if times >= 2
        done()
      Tests.Fetch 1

    Tests.Fetch 1
    .then (test) ->
      test.test++
      test.Save ->
        handler.Stop()

  test 'should not watch changes for Fetch ', (done) ->
    times = 0
    # console.log
    handler = Nodulator.Watch ->
      times++
      if times >= 2
        done()
      Tests.Fetch 1

    Tests.Fetch 2
    .then (test) ->
      test.test++
      test.Save()

    setTimeout ->
      handler.Stop()
      done() if times is 1
    , 100

  test 'should watch changes for List I', (done) ->
    times = 0
    # console.log
    handler = Nodulator.Watch ->
      times++
      if times is 2
        done()
      Tests.List()

    Tests.Fetch 1
    .then (test) ->
      test.test++
      test.Save ->
        handler.Stop()

  test 'should not watch changes for List I', (done) ->
    times = 0
    # console.log
    handler = Nodulator.Watch ->
      times++
      if times is 2
        done()
      Tests.List {test: 1}

    Tests.Fetch 6
    .then (test) ->
      test.test = 42
      test.Save()

    setTimeout ->
      handler.Stop()
      done() if times is 1
    , 100

  test 'should watch changes for List II', (done) ->
    times = 0
    # console.log
    handler = Nodulator.Watch ->
      times++
      if times is 2
        handler.Stop()
        done()
      Tests.List {test: 1}

    Tests.Fetch 3
    .then (test) ->
      test.test++
      test.Save ->

  test 'should watch changes for List III', (done) ->
    times = 0
    # console.log
    handler = Nodulator.Watch ->
      times++
      if times is 2
        done()
      Tests.List [{test: 1}, {test: 2}]

    Tests.Fetch 6
    .then (test) ->
      test.test = 1
      test.Save ->
        handler.Stop()
