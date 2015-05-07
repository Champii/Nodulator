_ = require 'underscore'
async = require 'async'
supertest = require 'supertest'
assert = require 'assert'

Nodulator = require '../'

TestResource = null
ChildResource = null
NewResource = null

describe 'Nodulator Associations', ->

  before (done) ->
    Nodulator.Reset ->
      ChildResource = Nodulator.Resource('child').Init()
      ChildResource.Create {field: 'child'}, (err, child) -> return console.error err if err?

      testConfig =
        schema:
          childId: 'int'
          child:
            type: ChildResource
            localKey: 'childId'

      TestResource = Nodulator.Resource 'test', testConfig
      assert TestResource?
      TestResource.Init()

      done()

  it 'should fetch child Resource', (done) ->
    blob =
      childId: 1

    TestResource.Create blob, (err, test) ->
      return done err if err?

      assert.equal test.child.field, 'child'

      done()

  it 'should create another resource with array of association', (done) ->
    ChildResource.Create
      field: 'child2'
    , (err, res) ->
      return console.error err if err?

    newConfig =
      schema:
        childIds: ['int']
        children:
          type: [ChildResource]
          localKey: 'childIds'

    NewResource = Nodulator.Resource 'new', newConfig
    assert NewResource?
    NewResource.Init()

    done()

  it 'should fetch every child Resource', (done) ->
    blob =
      childIds: [1, 2]

    NewResource.Create blob, (err, instance) ->
      return done err if err?

      assert.equal instance.children.length, 2
      assert.equal instance.children[0].field, 'child'
      assert.equal instance.children[1].field, 'child2'

      done()


