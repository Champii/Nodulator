_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

N = require '..'

Tests = null
Childs = null
News = null

test = it

describe 'N Associations', ->

  beforeEach (done) ->
    N.Reset ->
      Childs := N \child

      Tests := N \test

      done!

  test 'should fetch one child Resource', (done) ->
    Tests.HasOne Childs
    Tests.Create name: \test
      .fail !-> throw new Error it

      .then ->
        Childs.Create name: \child1 testId: 1

      .fail !-> throw new Error it

      .then ->
        assert.equal it.Test.name, \test

      .then ->
        Tests.Fetch 1

      .then ->
        assert.equal it.Child.name, \child1
        assert.equal it.Child.testId, 1
        done!

      .fail !-> throw new Error it

  test 'should fetch many child Resource', (done) ->
    Tests.HasMany Childs
    Tests.Create name: \test
      .fail !-> throw new Error it

      .then ->
        Childs.Create name: \child1 testId: 1

      .then ->
        Childs.Create name: \child2 testId: 1

      .fail !-> throw new Error it

      .then ->
        assert.equal it.Test.name, \test

      .then ->
        Tests.Fetch 1

      .then ->
        assert.equal it.Childs.0.name, \child1
        assert.equal it.Childs.1.name, \child2
        assert.equal it.Childs.0.testId, 1
        assert.equal it.Childs.1.testId, 1
        done!

      .fail !-> throw new Error it

  test 'should fetch belonging parent', (done) ->
    Childs.BelongsTo Tests
    Tests.Create name: \test
      .fail !-> throw new Error it

      .then ->
        Childs.Create testId: 1

      .fail !-> throw new Error it

      .then ->
        assert.equal it.Test.name, \test
        done!

      .fail !-> throw new Error it

  # test 'should create another resource with array of association', (done) ->
  #   err, res <- Childs.Create do
  #     field: 'child2'
  #
  #   throw new Error err if err?
  #
  #   newConfig =
  #     schema:
  #       childIds: ['int']
  #       children:
  #         type: [Childs]
  #         localKey: 'childIds'
  #
  #   News := N 'new', newConfig
  #
  #   done!
  #
  # test 'should fetch every child Resource', (done) ->
  #   blob =
  #     childIds: [1, 2]
  #
  #   News.Create blob, (err, instance) ->
  #     throw new Error err if err?
  #
  #     assert.equal instance.children.length, 2
  #     assert.equal instance.children[0].field, 'child'
  #     assert.equal instance.children[1].field, 'child2'
  #
  #     done!
  #
  # test 'should fetch distantKey with array' (done) ->
  #   class Childs extends N 'child2', N.Route.MultiRoute
  #
  #   testConfig =
  #     schema:
  #       child:
  #         type: Childs
  #         distantKey: 'testId'
  #
  #   class Tests extends N 'test2', testConfig
  #
  #   Childs.Create testId: 1 field: 'child'
  #   .fail -> throw new Error it
  #   .then -> Tests.Create test: \test
  #   .then ->
  #     assert.equal it.child.field, 'child'
  #     done!
  #
  # test 'should fetch distantKey with array of association' (done) ->
  #   Childs = N 'child3'
  #
  #   testConfig =
  #     schema:
  #       children:
  #         type: [Childs]
  #         distantKey: 'testId'
  #
  #   Tests = N 'test3', testConfig
  #
  #   Childs.Create testId: 1 field: 'child'
  #   .fail -> throw new Error it
  #   .then -> Tests.Create test: \test
  #   .then ->
  #     assert.equal it.children.0.field, 'child'
  #     done!
