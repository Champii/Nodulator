Modulator
============

  Set of class for CoffeeScript to create tiny API easely

  Tends to be a easy to use library, with basic auth system, classic Db system

  (Can be used in Javascript, obviously, but not tested yet)

  Based on:

    async
    express
    underscore
    mysql
    body-parser
    cookie-parser
    passport
    passport-local
    express-session
    mocha
    assert
    superagent
    supertest


#Usage#

  Requirement:

    Modulator = require './lib/Modulator'

  Resource declaration is easy.

    APlayer = Modulator.Resource 'player'

  It create automaticaly a Document (in ram for the moment, and no fixed fields)

  It create also default routes

    GET   /api/1/players       => List
    GET   /api/1/players/:id   => Get One
    POST  /api/1/players       => Create
    PUT   /api/1/players/:id   => Update

  It include 6 methods

    *Fetch(id, done)
    *List(done)
    *Deserialize(blob, done)
    Save(done)
    Serialize()
    ToJSON()

    * Class methods

  You can now extends the resource

    class PlayerResource extends APlayer

      constructor: (blob) ->    # Optional
        super blob              #

      LevelUp: (done) ->
        @level++
        @Save done

  (Here we have a custom method: LevelUp)

  You can define custom routes:

    PlayerResource.Route 'put', '/:id/levelUp', (req, res) ->
      PlayerResource.Fetch req.params.id, (err, player) ->
        return res.send 500 if err?

        player.LevelUp (err) ->
          return res.send 500 if err?

          res.send 200, player.ToJSON()

  It define :

    PUT   /api/1/players/:id/levelUp

  Open exemple.coffee to see a better exemple

#Config#

  Config system actualy permit to switch betwin InRAM Document system (Default value, no persistant data) and Mysql.

  You have to call Config method only once, and before declaring any resources.

    Modulator.Config
      dbType: 'Mysql'   # You can select 'SqlMem' to use inRAM Document (no persistant data, used to test)
      dbAuth:
        host: 'localhost'
        user: 'test'
        pass: 'test'
        database: 'test'

  If you omit to call Config, it will takes default value (dbType: 'SqlMem')

#Auth#

  You can assign a Ressource as AccountResource :

    APlayer = Modulator.Resource 'player',
      account: true

  Defaults fields are 'username' and 'password'

  You can change them :

    APlayer = Modulator.Resource 'player',
      account:
        fields:
          usernameField: "login"
          passwordField: "pass"

  It creates a custom method from usernameField

    *FetchByUsername(username, done)

      or if customized

    *FetchByLogin(login, done)

    * Class methods

    /!\ WARNING BUG /!\
    Theses methods return Resource object instead of extended object

  It defines 2 routes :

    POST  /api/1/players/login
    POST  /api/1/players/logout

  It setup session system, and thanks to Passport,

  it fills req.user variable to handle public/authenticated routes


#To Do#

  By order of priority

    Document DB (mongo)
    Delete record system
    Override default routes
    General architecture and file generation
    Better routing system (Auto add on custom method ?)
    Error management
    Advanced Auth (Social + custom)
    Basic view system
    Relational models
    Better Config system
