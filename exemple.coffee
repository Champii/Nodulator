Modulator = require '../lib/Modulator'
Permissions = require '../lib/Permissions'
Authentication = require '../lib/Authentication'

# Simple model test
###
Track = Modulator.Resource('track')

test = new Track('a': 1)

test.Save (err, obj) ->
  console.log 'Save : ' + obj

Track.Fetch 1, (err, obj) ->
  console.log obj

Track.List (err, obj) ->
  console.log obj

console.log test.Serialize()

test.Delete () ->
  console.log 'Delete done'

Track.Fetch 1, (err, obj) ->
  console.log err

# Overloaded model test

console.log TrackTest.Deserialize {'a' :'b'}, (err, obj) -> console.log obj

test2 = new TrackTest('b' : 2)
console.log test2.Serialize()

## Route test

###

# Overloading route

class TrackRoute extends Modulator.Route
  constructor: (resource, app) ->
    super resource, app

    @add 'get', @test_id, '/:idm/test/:idp'

  get: (req, res) ->
    res.status(200).send({"OVERLOADED"})

  test_id: (req, res) ->
    console.log 'test_id'
    res.status(200).send({"YAI"})

# FIXME : Trackroute s'est fixe sur Track comme resource
#         Il faut pouvoir acceder a l'instance de route dans Track
class TrackTest extends Modulator.Resource('track', TrackRoute)
  # Static methods
  @Deserialize: (blob, done) ->
    console.log 'Overloaded Deserialize : track'
    super blob, done

  # Instance Methods
  Serialize: ->
    console.log 'Overloaded Serialize : track'
    super

TrackTest.setRoutes()

class PlaylistRoute extends Modulator.Route
  constructor: (resource, app, config) ->
    super resource, app, config

    @add 'get', @test_id, '/:idm/test/:idp'

  get: (req, res) ->
    res.status(200).send({"OVERLOADED"})

  test_id: (req, res) ->
    console.log 'test_id'
    res.status(200).send({"YAI"})

PlaylistTestConfig =
  permissions:
    'get-/:id*': Permissions.ownedBy
  restrict : Authentication.auth

class PlaylistTest extends Modulator.Resource('playlist', PlaylistRoute, PlaylistTestConfig)
  # Static methods
  @Deserialize: (blob, done) ->
    console.log 'Overloaded Deserialize : playlist'
    super blob, done

  # Instance Methods
  Serialize: ->
    console.log 'Overloaded Serialize : playlist'
    super

PlaylistTest.setRoutes()

PlayerConfig =
  account: true

###
  test: (done) ->
    (req, res, next) ->
      console.log 'test: YEAH'
      done req, res, next
  ah:
    post: (done) ->
      (req, res, next) ->
        console.log 'ah: POST YEAH!'
        done req, res, next

    'get-/:id*': (done) ->
      (req, res, next) ->
        console.log 'ah: GET-ID YAH MAN!'
        done req, res, next
###

Player = Modulator.Resource('player', PlayerConfig)

console.log 'Server is running'

Modulator.ListEndpoints (endpoints) -> console.log endpoints
