# Nodulator


## Concept

Nodulator is designed to make it more easy to create highly modulable REST APIs, with integrated ORM (database agnostic) in CoffeeScript.


Open [exemple.coffee](https://github.com/Champii/Nodulator/blob/master/exemple.coffee) to see a full working exemple

___
### Compatible modules
- [Nodulator-Assets](https://github.com/Champii/Nodulator-Assets): Automatic assets management and inclusion
- [Nodulator-Angular](https://github.com/Champii/Nodulator-Angular): Angular class set, add inheritance systeme and default behaviour.

___
## Jump To
- [Installation](#installation)
- [Project Generation](#project-generation)
- [Config](#config)
- [Resource](#resources)
  - [Class methods](#class-methods)
  - [Instance methods](#instance-methods)
- [Overriding and Inheritance](#overriding-and-inheritance)
  - [Override default behaviour](#override-default-behaviour)
  - [Complex inheritance system](#complex-inheritance-system)
- [Route](#routes)
  - [Route Object](#route-object)
  - [DefaultRoute](#default-route-object)
  - [Route Inheritance](#route-inheritance)
- [Auth](#auth)
- [Restriction](#restriction)
- [DOC (Deprecated)](#doc)
- [TODO](#todo)

___
### Installation 

Just run :
    npm install nodulator

After you can require `Nodulator` as a module :

```coffeescript
    Nodulator = require 'nodulator'
```

___
### Project Generation
(BETA Feature)
USE IT IN AN EMPTY FOLDER

You can use `coffee ./node_modules/nodulator/scripts/index.coffee init`    
It creates the following structure :
```
main.coffee
package.json
settings/
server/
├── index.coffee
├── processors/
│   └── index.coffee
├── resources/
│   ├── index.coffee
└── sockets/
    └── index.coffee
```

You can immediatly start to write resources in server/resources
___
### Config

First of all, the config process is absolutly optional.  
If you don't give Nodulator a config, it will assume you want to use SqlMem DB system, with no persistance at all. Usefull for heavy tests periods.

If you prefere to use a persistant system, here is the procedure :

```coffeescript
    Nodulator = require 'nodulator'
    
    Nodulator.Config
      dbType: 'Mongo'       # You can select 'SqlMem' to use inRAM Document (no persistant data, used    to test) or 'Mongo' or 'Mysql'
      dbAuth:
        host: 'localhost'
        database: 'test'
        port: 27017       # Can be ignored, default values taken
        user: 'test'      # For Mongo and SqlMem, these fields are optionals
        pass: 'test'      #
```

The module provide 2 main Objects :

```coffeescript
    Nodulator.Resource
    Nodulator.Route
```

___
### Resources

A `Resource` is a class permitting to retrive and save a model from a DB.

Here is an exemple of creating a `Resource`

```coffeescript
    PlayerResource = Nodulator.Resource 'player'

    PlayerResource.Init()
    # /!\ Never forget to call Init() /!\ #
```

You can pass several params to `Modulator.Resource` : 

```coffeescript
    Modulator.Resource name [, Route] [, config]
```

#### Class methods

Each `Resource` provides some 'Class methods' to manage the specific model in db :

```coffeescript
    PlayerResource.Fetch(id, done)
    PlayerResource.FetchBy(field, value, done)
    PlayerResource.List(id, done)
    PlayerResource.ListBy(field, value, done)
    PlayerResource.Deserialize(blob, done)
```

The `Fetch` method take an id and return a `PlayerResource` intance to `done` callback :

```coffeescript
    PlayerResource.Fetch 1, (err, player) ->
      return console.error err if err?

      [...] # Do something with player
```

You can also call `FetchBy` method to give a specific field to retrive.  
It can be unique, or the first occurence in DB will return.

You can list every models from this `Resource` thanks to `List` :

```coffeescript
    PlayerResource.List (err, players) ->
      return console.error err if err?

      [...] # players is an array of player instance
```

Like `Fetch`, you can `ListBy` a specific field.

The `Deserialize` method allow to get an instance of a given `Resource`.  
Never use `new` operator directly on a `Resource`, else you might bypass the relationning system.  
`Deserialize` method used to make pre-processing work (like fetching related models) before instantiation.

#### Instance methods

A player instance has some methods :

    player.Save(done)
        Used to save the model in DB. The callback take 2 arguments : (err, instance) ->

    player.Delete(done)
        Used to delete the model from the DB. The callback take 1 argument : (err) ->

    player.Serialize()
        Used to get every object properties, and return it in a new object.
        Generaly used to get what to be saved in DB.

    player.ToJSON()
        By default, it calls Serialize().
        Generaly used to get what to send to client.

____
### Overriding and Inheritance

You can inherit from a `Resource` to override or enhance its default behaviour, or to make a complex class inheritance system built on `Resource`

#### Override default behaviour
In CoffeeScript its pretty easy:

```coffeescript
    class UnitResource extends Nodulator.Resource 'unit'
      # Here we override the constructor to attach a weapon resource
      # Never forget to call super(blob), or the instance will never be populated by DB fields
      constructor: (blob, @weapon) ->
        super blob
      
      # We create a new instance method
      LevelUp: (done) ->
        @level++
        @Save done
      
      # Here we override the Deserialize class method, to fetch the attached WeaponResource
      @Deserialize: (blob, done) ->
        if !(blob.id?)        # If the resource isnt deserialized from db, don't fetch attached resource
          return super blob, done

          WeaponResource.FetchByUserId blob.id, (err, weapon) =>
            res = @
            done(null, new res(blob, weapon))

      UnitResource.Init()
```

#### Complex inheritance system

Given the last exemple, here is a class that inherits from `UnitResource`

```coffeescript
    class PlayerResource extends UnitResource.Extend 'player'
      
      SpecialBehaviour: (args, done) ->
        [...]

    PlayerResource.Init();
```

You can also define abstract class, to avoid corresponding model to be created/initialized :

```coffeescript
    class UnitResource extends Nodulator.Resource 'unit', {abstract: true}
      
    UnitResource.Init();
```

Of course, abstract class are only designed to be inherited. (Please note that they can't have Route attached)

___
### Routes

#### Route Object

Nodulator provides a `Route` object, to be attached to a `Resource` object in order to describe routing process.

```coffeescript
    class UnitResource extends Nodulator.Resource 'unit', Nodulator.Route
```

There is no need of `Init()` here.   
Default `Nodulator.Route` do nothing.   
You have to inherit from it to describe routes :

```coffeescript
    class UnitRoute extends Nodulator.Route
      Config: ->
        super()
        @Add 'get', '/:id', (req, res) =>
          # The @resource field points to attached Resource
          @resource.Fetch req.params.id, (err, unit) ->
            return res.status(500).send err if err?

            res.status(200).send unit.ToJSON()

        @Add 'post', (req, res) ->
          res.status(200).end();
```

This `Route`, attached to a `Resource`, add 2 endPoints :
    
    GET  => /api/1/units/:id
    POST => /api/1/units

Each `Route` have to implement a `Config()` method, calling `super()` and defining routes thanks to `@Add()` call.   
Here is the `@Add()` call definition :

```coffeescript    
    Nodulator.Route.Add verb, [endPoint = '/'], [middleware, [middleware, ...]], callback
```
   
#### Default Route Object

Nodulator provides also a standard route system for lazy : `Nodulator.Route.DefaultRoute`.    
It setup 5 routes (exemple when attached to a PlayerResource) : 

    GET     /api/1/players       => List
    GET     /api/1/players/:id   => Get One
    POST    /api/1/players       => Create
    PUT     /api/1/players/:id   => Update
    DELETE  /api/1/players/:id   => Delete

#### Route Inheritance

You can inherit from any route object :

```coffeescript
    class TestRoute extends Nodulator.Route.DefaultRoute
```
And you can override existing route by providing same association verb + url. Exemple :

```coffeescript
    class TestRoute extends Nodulator.Route.DefaultRoute
      Config: ->
        super()

        # Here we override the default Get from Id
        @Add 'get', '/:id', (req, res) =>
          [...]
```
___
##Auth

Authentication is based on Passport    
You can assign a Ressource as AccountResource :    

```coffeescript
    config = 
      account: true

    class PlayerResource extends Nodulator.Resource 'player', config
```

Defaults fields are 'username' and 'password'

You can change them (optional) :

```coffeescript
    config = 
      account:
        fields:
          usernameField: "login"
          passwordField: "pass"

    class PlayerManager extends Nodulator.Resource 'player', config
```


It creates a custom method from usernameField

    *FetchByUsername(username, done)

      or if customized

    *FetchByLogin(login, done)

    * Class methods

It defines 2 routes :

    POST    /api/1/players/login
    POST    /api/1/players/logout

It setup session system, and thanks to Passport,    
It fills req.user variable to handle public/authenticated routes

You have to `extend` yourself the `post` default route (for exemple) of your resource to use it as a signup route.

#Restriction#

USER:

You can restrict access to a resource :

```coffeescript
    config =
      account: true
      restricted: 'user' #Can be 'user', 'auth', or an object

    class PlayerResource extends Nodulator.Resource 'player', config
```

This code create a APlayer resource that is an account,   
and only player itself can access to its resource (GET, PUT and DELETE on own /api/1/players/:id)   

POST and GET-without-id are still accessible for anyone (you can override them)
/!\ 'user' keyword must only be used on account resource

AUTH:

You can restrict access to a resource for authenticated users only :

```coffeescript
    PlayerResource = Nodulator.Resource 'player',
      restricted: 'auth'
```


This code create a ATest resource that can only be accessed by auth users


OBJECT:

You can restrict access to a resource for users that have particular property set :

```coffeescript
    PlayerResource = Nodulator.Resource 'player',
      restricted:
        group: 1
        x: 'test'
```

It will deny access to whole resource for any users that don't have theses properties set

It's not possible anymore to put a certain rule on a certain route. Theses rules apply to the whole resource.

___
## DOC
 (DEPRECATED)

  Nodulator

    Nodulator.Resource(resourceName, [config])

      Create the resource Class to be extended (if necessary)

    Nodulator.Config(config)

      Change config

    Nodulator.app

      The express main app object

  Resource

  (Uppercase for Class, lowercase for instance)

    Resource.Route(type, url, [restricted], done)

      Create a route.

      'type' can be 'all', 'get', 'post', 'put' and 'delete'
      'url' will be concatenated with '/api/{VERSION}/{RESOURCE_NAME}'
      'restricted' is optional and defines if user must be restricted to see
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


## ToDo

  By order of priority

    Error management
    Better++ routing system (Auto add on custom method ?)
    General architecture and file generation
    Advanced Auth (Social + custom)
    Basic view system
    Relational models
