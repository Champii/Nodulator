_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Nodulator = require '../lib/Nodulator'

Tests = null
Childs = null
News = null

describe 'Nodulator Associations', ->

  before (done) ->
    Nodulator.Reset ->
      Childs = Nodulator.Resource 'child'
      Childs.Create {field: 'child'}, (err, child) -> return console.error err if err?

      testConfig =
        schema:
          childId: 'int'
          child:
            type: Childs
            localKey: 'childId'

      Tests = Nodulator.Resource 'test', testConfig

      done()

  it 'should fetch child Resource', (done) ->
    blob =
      childId: 1

    Tests.Create blob, (err, test) ->
      return done err if err?

      assert.equal test.child.field, 'child'

      done()

  it 'should create another resource with array of association', (done) ->
    Childs.Create
      field: 'child2'
    , (err, res) ->
      return console.error err if err?

    newConfig =
      schema:
        childIds: ['int']
        children:
          type: [Childs]
          localKey: 'childIds'

    News = Nodulator.Resource 'new', newConfig

    done()

  it 'should fetch every child Resource', (done) ->
    blob =
      childIds: [1, 2]

    News.Create blob, (err, instance) ->
      return done err if err?

      assert.equal instance.children.length, 2
      assert.equal instance.children[0].field, 'child'
      assert.equal instance.children[1].field, 'child2'

      done()
