Modulator
============

  Set of class for CoffeeScript to create tiny API easely

  Tends to be a easy to use library, with basic auth system (Passport) and classic DB systems (Mysql/Mongo/RAM)

  (Can be used in Javascript, obviously, but not tested yet)

  Based on:

    async
    express
    underscore
    mysql
    mongous
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

  It create automaticaly a Document (for Mongo or SqlMem)

  No fixed fields, excepted for Mysql: you have to follow thefields you have defined in your database

  It create also default routes

    GET     /api/1/players       => List
    GET     /api/1/players/:id   => Get One
    POST    /api/1/players       => Create
    PUT     /api/1/players/:id   => Update
    DELETE  /api/1/players/:id   => Delete

  For those that need an id, resource is automaticaly fetched and put in req.player (if your resource is 'player')

  It include 7 methods

    *Fetch(id, done)
    *List(done)
    *Deserialize(blob, done)
    Save(done)
    Delete(done)
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
      req.player.LevelUp (err) ->
        return res.send 500 if err?

        res.send 200, req.player.ToJSON()

  Here we used a route that take an id.

  A middleware has automaticaly fetched our resource and has put it in req.player

  It defines :

    PUT     /api/1/players/:id/levelUp

  Open exemple.coffee to see a better exemple

#Config#

  Config system actualy permit to switch between Mysql, Mongo and 'In RAM' Document system (Default value, no persistant data).

  You have to call Config method only once, and before declaring any resources.

    Modulator.Config
      dbType: 'Mongo'         # You can select 'SqlMem' to use inRAM Document (no persistant data, used to test) or 'Mongo' or 'Mysql'
      dbAuth:
        host: 'localhost'
        database: 'test'
        # port: 27017         # Can be ignored, default values taken
        # user: 'test'        # For Mongo, these fields are optionals
        # pass: 'test'        #

  If you omit to call Config, it will takes default value (dbType: 'SqlMem')

#Auth#

  Authentication is based on Passport

  You can assign a Ressource as AccountResource :

    APlayer = Modulator.Resource 'player',
      account: true

  Defaults fields are 'username' and 'password'

  You can change them (optional) :

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

    POST    /api/1/players/login
    POST    /api/1/players/logout

  It setup session system, and thanks to Passport,

  it fills req.user variable to handle public/authenticated routes


#DOC#

  Modulator

    Modulator.Resource(resourceName, [config])

      Create the resource Class to be extended (if necessary)

    Modulator.Config(config)

      Change config

    Modulator.app

      The express main app object

  Resource

  (Uppercase for Class, lowercase for instance)

    Resource.Route(type, url, [registrated], done)

      Create a route.

      'type' can be 'all', 'get', 'post', 'put' and 'delete'
      'url' will be concatenated with '/api/{VERSION}/{RESOURCE_NAME}'
      'registrated' is optional and defines if user must be registrated to see
      'done' is the express app callback: (req, res, next) ->

    Resource.Fetch(id, done)

      Take an id and return it from the DB in done callback: (err, resource) ->

    Resource.List(done)

      Return every records in DB for this resource and give them to done: (err, resources) ->

    Resource.Deserialize(blob, done)

      Method that take the blob returned from DB to make a new instance

    resource.Save(done)

      Save the instance in DB

      If the resource doesn't exists, it create and give it an id
      It return to done the current instance

    resource.Delete(done)

      Delete the record in DB, and return affected rows in done

    resource.Serialize()

      Return every properties that aren't functions or objects or are undefined
      This method is used to get what must be saved in DB

    resource.ToJSON()

      This method is used to get what must be send to client
      Call @Serialize() by default, but can be overrided


#To Do#

  By order of priority

    Override default routes
    Test suite
    Error management
    Better++ routing system (Auto add on custom method ?)
    General architecture and file generation
    Advanced Auth (Social + custom)
    Basic view system
    Relational models
