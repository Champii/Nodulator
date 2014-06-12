CoffeeHelper
============

  Set of class for CoffeeScript to create tiny API easely

  (Can be used in Javascript, obviously, but not tested yet)

  Based on:

    async
    express
    underscore
    coffee-middleware
    socket.io
    passport
    passport-local
    cookie-parser
    body-parser
    express-session
    jade
    mocha
    assert
    superagent
    supertest


#Usage#

  Requirement:

    CoffeeHelper = require './lib/CoffeeHelper'

  Resource declaration is easy.

    APlayer = CoffeeHelper.Resource 'player'

  Now you can create the resource itself

    class PlayerResource extends APlayer

      constructor: (blob) ->    # Optional
        super blob              #

      LevelUp: (done) ->
        @level++
        @Save done

  (Here we have a custom method: LevelUp)

  It create automaticaly a table (in ram for the moment)

  It create also default routes

    GET   /api/1/player       => List
    GET   /api/1/player/:id   => Get One
    POST  /api/1/player       => Create
    PUT   /api/1/player/:id   => Update

  It include 6 methods

    *Fetch(id, done)
    *List(done)
    *Deserialize(blob, done)
    Save(done)
    Serialize()
    ToJSON()

    * Class methods

  You can define custom routes:

    PlayerResource.Route 'put', '/:id/levelUp', (req, res) ->
      PlayerResource.Fetch req.params.id, (err, player) ->
        return res.send 500 if err?

        player.LevelUp (err) ->
          return res.send 500 if err?

          res.send 200, player.ToJSON()

  It define :
    PUT   /api/1/player/:id/levelUp


#To Do#

  By order of priority

    Persistant DB (sql/mongo)
    Clean dirty tricks (@SetHelpers in Resource)
    Config system (ex: Table/Document, depends on db type)
    General architecture and file generation
    Basic view system
    Better routing system (Auto add on custom method ?)
    Basic Auth (Passport ?)
