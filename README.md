# Nodulator

[![Build Status](https://travis-ci.org/Champii/Nodulator.svg?branch=master)](https://travis-ci.org/Champii/Nodulator) (Master)

[![Build Status](https://travis-ci.org/Champii/Nodulator.svg?branch=develop)](https://travis-ci.org/Champii/Nodulator) (Develop)

[![NPM](https://nodei.co/npm/nodulator.png?downloads=true&downloadRank=true&stars=true)](https://nodei.co/npm/nodulator/)

[![NPM](https://nodei.co/npm-dl/nodulator.png?months=1)](https://nodei.co/npm/nodulator/)

##### Under heavy development

___
## Concept

`Nodulator` is designed to make it more easy to create highly modulable applications, built with REST APIs and with integrated ORM in CoffeeScript.

You must understand [express](https://github.com/strongloop/express) basics for routing

Open [exemple.coffee](https://github.com/Champii/Nodulator/blob/master/exemple.coffee) to see a full working exemple

Released under [GPLv2](https://github.com/Champii/Nodulator/blob/master/LICENSE.txt)

___
## Jump To

- [Philosophy](#philosophy)
- [Features](#features)
- [Compatible modules](#compatible-modules)
- [Installation](#installation)
- [Quick Start](#quick-start)
- [Configuration](#configuration)
- [Resource](#resource)
  - [Basics](#basics)
  - [Class methods](#class-methods)
  - [Instance methods](#instance-methods)
  - [Schema and Validation](#schema-and-validation)
  - [Model association](#model-association)
- [Overriding and Inheritance](#overriding-and-inheritance)
  - [Override default behaviour](#override-default-behaviour)
  - [Abstract Class](#abstract-class)
  - [Complex inheritance system](#complex-inheritance-system)
- [Route](#route)
  - [Route Object](#route-object)
  - [SingleRoute](#single-route-object)
  - [MultiRoute](#multi-route-object)
  - [Route Inheritance](#route-inheritance)
- [DB Systems](#db-systems)
  - [Abstraction](#abstraction)
  - [Mysql](#mysql)
  - [MongoDB](#mongodb)
  - [SqlMem](#sqlmem)
- [Other Stuff](#other-stuff)
  - [Bus](#bus)
- [Modules](#modules)
  - [Usage](#usage)
  - [Module Hacking](#module-hacking)
- [Project Generation](#project-generation)
- [Developers](#developers)
- [Contributors](#contributors)
<!-- - [DOC](#doc) -->
- [TODO](#todo)
- [Changelog](#changelog)

___
## Philosophy

`Nodulator` is a project that is trying to make a big overlay to every traditionnal packages used to make REST client/server applications in CoffeeScript.
Its main goal is to give developers a complex REST routing system, an ORM and high-level modules, encapsulating every classic behaviour needed to create complex projects.

Its core provides everything needed to build powerfull and highly modulable REST APIs, and allow the developer to reuse his code through every projects.

With this framework, you will never loose 10 or 20 hours anymore boostraping a project from scratch or looking for the right technology to implement.
You will never have headache anymore trying to combine `socket.io` and `passport` to keep track of your session with your sockets (for exemple),
or you will never have to consider assets management,
and with the integrated [Project Generation](#project-generation) you will never need to manage your `Nodulator` modules dependencies.

You need to add authentication logic to your open/public API ? Look for [Nodulator-Account](https://github.com/Champii/Nodulator-Account) !

You need to add socket.io support ? Look for [Nodulator-Socket](https://github.com/Champii/Nodulator-Socket) !

If you don't find your desired module, just [build it](#modules) !

`Nodulator` is like a lego game, instead of learning how to use a given technology and how to combine it with thoses you often use,
it allows you to manipulate simple concepts like adding a `Account` concept to your application(for exemple), and so adding authentication and permission logic to your app.

Also, each brick or layer of a `Nodulator` application is highly linked to every others.
For exemple, when you add `Nodulator-Account` module to your app, if you have already included `Nodulator-Angular` it will automaticaly add everything needed
to handle angular authentication (it will add a separate view, some directives and a user service). Have you added `Nodulator-Socket` ?
So `Nodulator-Angular` will also be highly linked to your server's models, by providing a socket interface to your server `Resource`.

Check the [Jump To](#jump-to) section !

___
## Features

- Integrated ORM
- Integrated Routing system (with express, and highly linked with ORM)
- Multiple DB Systems
- Complex inheritance system
- Modulable
- Project generation
- Schema-less/Schema-full models
- Model validation
- Model association and automatic retrieval

___
### Compatible modules

- [Nodulator-Assets](https://github.com/Champii/Nodulator-Assets):
  - Automatic assets management
- [Nodulator-Socket](https://github.com/Champii/Nodulator-Socket):
  - Socket.io implementation for Nodulator
- [Nodulator-Angular](https://github.com/Champii/Nodulator-Angular):
  - Angular implementation for Nodulator
  - Inheritance system
  - Integrated and linked SocketIO
  - Assets management
- [Nodulator-Account](https://github.com/Champii/Nodulator-Account):
  - Authentication with passport
  - Permissions management
  - Sessions
  - Nodulator-Angular integration

___
## Installation

Just run :
```
npm install nodulator
```
Or check the [Project Generation](#project-generation) section

After you can require `Nodulator` as a module :

```coffeescript
Nodulator = require 'nodulator'
```

___
## Quick Start

Here is the quickiest way to play around `Nodulator`

```coffeescript
_ = require 'underscore'
Nodulator = require 'nodulator'

class PlayerRoute extends Nodulator.Route.MultiRoute
  Config: ->

    # We create: GET => /api/1/{resource_name}/usernames
    # Get a list of every players' usernames
    @Get '/usernames', (req, res) =>

      # There is a @resource property, containing attached Resource class
      @resource.ListUsernames (err, usernames) ->
        return res.status(500).send err if err?

        res.status(200).send usernames

    # We call super() to apply Nodulator.Route.MultiRoute behaviour
    # We called '/usernames' route before, so it won't be override by
    # default route GET => /api/1/{resource_name}/:id
    super()

    # We create: PUT => /api/1/{resource_name}/:id/levelUp
    @Put '/:id/levelUp', (req, res) =>

      # For MultiRoute routes with '/:id/*',
      # Fetch the corresponding Resource and put the instance in @instance
      # (here it can be called 'req.player' but we want to stay generic)
      @instance.LevelUp (err, resource) ->
        return res.status(500).send err if err?

        res.status(200).send resource.ToJSON()

# We create a resource, and we attach the PlayerRoute
class PlayerResource extends Nodulator.Resource 'player', PlayerRoute

  # We create a LevelUp method
  LevelUp: (done) ->
    @level++
    @Save done

  # And a class method to get a list of usernames
  @ListUsernames: (done) ->
    @List (err, players) ->
      return done err if err?

      done null, _(players).pluck 'username'

# And we Init()
PlayerResource.Init()

```

Go inside your project folder, copy this POC in a `test.coffee` file and type in:

`$> coffee test.coffee`

It will run your project on port `3000` by default

Then open your favorite REST API Client ([Postman for Chrome](https://www.google.fr/url?sa=t&rct=j&q=&esrc=s&source=web&cd=1&cad=rja&uact=8&ved=0CCMQFjAA&url=https%3A%2F%2Fchrome.google.com%2Fwebstore%2Fdetail%2Fpostman-rest-client%2Ffdmmgilgnpjigdojojpjoooidkmcomcm%3Fhl%3Den&ei=Tu6iVMqpJZDaatmGgOAL&usg=AFQjCNHaecLwAKk91gpdCY_y1x_ViIrHwQ&sig2=3FcPD7i2Id8La26xJt4PJA&bvm=bv.82001339,d.d2s) is my favorite)

and try the following routes :

```
(Assuming full url is always of the following form : "http://localhost:3000/api/1/[...]")
Each route is of the following form :

{VERB}  {URL}                       ({PARAMS})                       => {ANSWER}

POST    '/api/1/players'            {username: 'test1', level: 1}    => {id: 1, username: 'test1', level: 1}
POST    '/api/1/players'            {username: 'test2', level: 1}    => {id: 2, username: 'test2', level: 1}

GET     '/api/1/players'                                             => [{id: 1, username: 'test1', level: 1},
                                                                         {id: 2, username: 'test2', level: 1}]

GET     '/api/1/players/1'                                           => {id: 1, username: 'test1', level: 1}
GET     '/api/1/players/2'                                           => {id: 2, username: 'test2', level: 1}

PUT     '/api/1/players/2/levelUp'  {}                               => {id: 2, username: 'test2', level: 2}
PUT     '/api/1/players/2/levelUp'  {}                               => {id: 2, username: 'test2', level: 3}

GET     '/api/1/players/usernames'                                   => ['test1', 'test2']

PUT     '/api/1/players/2'          {username: 'notAUsername'}       => {id: 2, username: 'notAUsername', level: 3}

GET     '/api/1/players/usernames'                                   => ['test1', 'notAUsername']

DELETE  '/api/1/players/1'          {}                               => {id: 1, username: 'test1', level: 1}

GET     '/api/1/players/usernames'                                   => ['notAUsername']
```

___
## Configuration

First of all, the configuration process is absolutly optional.

If you don't give Nodulator a config, it will assume you want to use [SqlMem](#sqlmem) DB system, with no persistance at all. Usefull for heavy tests periods.

If you prefere to use a persistant system, here is the procedure :

```coffeescript
Nodulator = require 'nodulator'

Nodulator.Config
  dbType: 'Mongo'     # You can select 'SqlMem' or 'Mongo' or 'Mysql'
  dbAuth:             # Fields needed if Mongo or Mysql
    host: 'localhost'
    database: 'test'
    port: 27017       # From there, can be ignored. Default values taken
    user: 'test'      # |
    pass: 'test'      # |_
```

You can also provide a 'store' property in order to use `Redis` to manage sessions:

```coffeescript
Nodulator = require 'nodulator'

Nodulator.Config
  store:
    type: 'redis'
    host: 'localhost'     # <- default value, can be ignored
```

If ommited, sessions will be memory based (not recommended)


`Nodulator` provides 2 main Objects :

```coffeescript
Nodulator.Resource
Nodulator.Route
```

___
## Resource

#### Basics

A `Resource` is a class permitting to retrive and save a model from a DB.

Here is an exemple of creating a `Resource`

```coffeescript
PlayerResource = Nodulator.Resource 'player'

PlayerResource.Init()
```

Here, it creates a `PlayerResource`, linked with a `players` table in DB (if any)

Note the 's' concatenated with the `Resource` name. Its the real `Resource.name` of a resource

For the same name without the 's', there is a `Resource.lname` property.

##### /!\ Never forget to call Init() /!\

It's needed in order to prepare the `Resource`. All the `Nodulator`'s magic is inside this call.

If you forget it :
- The `Resource` will NOT be linked to `Route` (if any)
- It will NOT prepare `Account` system (if any)
- It will NOT prepare inheritance system so you won't be able to inherit from it
- It will NOT be linked to a corresponding table in DB
- Nothing will work or happend. Ever.

##### /!\ Please read this section again /!\ (beware of infinite loops :p)

You can pass several params to `Nodulator.Resource` :

```coffeescript
Nodulator.Resource name [, Route] [, config]
```

You can attach a [Route](#route) and/or a config object to a `Resource`.


#### Class methods

Each `Resource` provides some 'Class methods' to manage the specific model in db :

```coffeescript
PlayerResource.Fetch(id, done)
PlayerResource.FetchBy(constraints, done)
PlayerResource.List(id, done)
PlayerResource.ListBy(constraints, done)
PlayerResource.Deserialize(blob, done)
PlayerResource.Create(blob, done)
```

The `Fetch` method take an id and return a `PlayerResource` intance to `done` callback :

```coffeescript
PlayerResource.Fetch 1, (err, player) ->
  return console.error err if err?

  [...] # Do something with player instance
```

You can also call `FetchBy` method to give a specific field to retrive.
It can be unique, or the first occurence in DB will return (depends on DB implementations)

You can list every models from this `Resource` thanks to `List` call :

```coffeescript
PlayerResource.List (err, players) ->
  return console.error err if err?

  [...] # players is an array of PlayerResource instance
```

Like `FetchBy`, you can `ListBy` a specific field.

The `Deserialize` method allow to get an instance of a given `Resource`.

Never use `new` operator directly on a `Resource`, else you might bypass the relationning system.

`Deserialize` method is used to make pre-processing work (like fetching related models) before instantiation.

`Create` method is an alias to `Deserialize` followed by a `Save`.

#### Instance methods

A player instance has some methods :

```
player.Save(done)
    Save the model in DB. The callback take 2 arguments : (err, instance) ->

player.Delete(done)
    Delete the model from the DB. The callback take 1 argument : (err) ->

player.Serialize()
    Get every object properties, and return it in a new object.
    Generaly used to get what to be saved in DB.

player.ToJSON()
    By default, it calls Serialize().
    Generaly used to get what to send to client.
```

#### Schema and Validation

By default, every `Resource` is schema less. It means that you can put almost anything into your `Resource`.

It can obviously be schema less only for DB systems that allows it. When using MySQL for exemple, you'll have
to define a schema and validation rules if you don't want your server to answer raw SQL errors for non existant fields

To make a `Resource` to respect a given schema, you just have to define a `schema` field into `Resource` configuration

```coffeescript
config =
  schema:
    toto:
      type: 'array' #This can be an array of everything
    test:
      type: ['int'] #This MUST be an array of integer
    foo:
      type: 'int'
    bar:
      type: 'string'
      optional: true
    foobar:
      type: 'string'
      default: 'foobar'
```

Differents types are
- bool
- int
- string
- date
- email
- array

By default, each fields is required, but you can make one field optional with the `optional` field to `true` or presence of `default` field. It will never complain if this field is not present, but if it is,
it will check for its validity.

If you specify a `default` field, the `Resource` will auto-set its property if not given.

You can specify a type directly with a string, assuming that the given property will be required:

```coffeescript
config =
  schema:
    foo: 'int'
    bar: 'string'
```


#### Model association

You can make associations between `Resource`. For making a `Resource` to be automaticaly fetched when querying another, you can add it to its schema :

```coffeescript
config =
  schema:
    foo:
      type: 'int'
    barId:
      type: 'int'
    bar:
      type: BarResource
      localKey: 'barId'

class TestResource extends Nodulator.Resource 'test', config

TestResource.Init()

# Fetch TestResource with id == 1
TestResource.Fetch 1, (err, test) ->
  # Will print for exemple : {id: 1, foo: 12, barId: 1, bar: {id:1, barProperty: 'test'}}
  console.log test
```

If you want to retrive a collection of resource, you can wrap types in arrays instead:

```coffeescript
config =
  schema:
    barIds:
      type: ['int']
    bar:
      type: [BarResource]
      localKey: 'barIds'

class TestResource extends Nodulator.Resource 'test', config

TestResource.Init()

# Fetch TestResource with id == 1
TestResource.Fetch 1, (err, test) ->
  # Will print for exemple : {id: 1, foo: 12, barIds: [1, 2], bar: [{id: 2, barProperty: 'test'}, {id: 2, barProperty: 'test2'}]}
  console.log test
```
____
## Overriding and Inheritance

You can inherit from a `Resource` to override or enhance its default behaviour, or to make a complex class inheritance system built on `Resource`

#### Override default behaviour
In CoffeeScript its pretty easy:

```coffeescript
class UnitResource extends Nodulator.Resource 'unit'

  # We create a new instance method
  LevelUp: (done) ->
    @level++
    @Save done

  # We override default 'List' method
  @List: (done) ->
    @ListBy {life: 10}, (err, units) ->
      return done err if err?

      done null, units

  UnitResource.Init()
```

#### Abstract class

You can define an abstract class, that won't be attached to any model in DB or any `Route`

```coffeescript
class UnitResource extends Nodulator.Resource 'unit', {abstract: true}
  [...]

UnitResource.Init();
```

Of course, abstract classes are only designed to be inherited. (Please note that they can't have a `Route` attached)

#### Complex inheritance system

Given the last exemple, here is a class that inherits from `UnitResource`

```coffeescript
# Note the call to 'Extend()' method
class PlayerResource extends UnitResource.Extend 'player'

  # Give PlayerResource a new beheviour
  NewBehaviour: (args, done) ->
    [...]

  # Overriding existing UnitResource LevelUp()
  LevelUp: (done) ->
    [...]

PlayerResource.Init();
```

You can call the Extend() method either from a full `Resource` or from an `abstract` one.

Please note that if both parent and child are full `Resource`, both will have corresponding model available from ORM (here `units` and `players`)

So be carefull when creating extended `Resource`, and think about `abstract` !

___
## Route

#### Route Object

`Nodulator` provides a `Route` object, to be attached to a `Resource` object in order to describe routing process.

```coffeescript
class UnitResource extends Nodulator.Resource 'unit', Nodulator.Route
```

There is no need of `Init()` here. Every `Route` is initiated and configured when its attached `Resource` is.

Default `Nodulator.Route` do nothing. You have to inherit from it to describe routes :

```coffeescript
class UnitRoute extends Nodulator.Route

  # Override the Config() method
  Config: ->

    # And never forget to call the super()
    super()

    # Here we define: GET => /api/1/{resource_name}/:id
    @Get '/:id', (req, res) =>

      # The @resource field points to attached Resource
      @resource.Fetch req.params.id, (err, unit) ->
        return res.status(500).send err if err?

        res.status(200).send unit.ToJSON()

    # Here we define: POST => /api/1/{resource_name}
    @Post (req, res) ->
      res.status(200).end()
```

This `Route`, attached to a `Resource` (here `UnitResource`) add 2 endpoints :

```
GET  => /api/1/units/:id
POST => /api/1/units
```

Each `Route` have to implement a `Config()` method, calling `super()` and defining routes thanks to 'verbs' route calls (@Get(), @Post(), @Put(), @Delete(), @All()).

Here are all 'verb' route calls definition :

```coffeescript
Nodulator.Route.All     [endPoint = '/'], [middleware, [middleware, ...]], callback
Nodulator.Route.Get     [endPoint = '/'], [middleware, [middleware, ...]], callback
Nodulator.Route.Post    [endPoint = '/'], [middleware, [middleware, ...]], callback
Nodulator.Route.Put     [endPoint = '/'], [middleware, [middleware, ...]], callback
Nodulator.Route.Delete  [endPoint = '/'], [middleware, [middleware, ...]], callback
```

#### Single Route Object

Nodulator provides a predefined route system for lazy, adapted for Singleton `Resource`: `Nodulator.Route.SingleRoute`.
It setups 2 routes (exemple when attached to a `PlayerResource`) :

```
GET     => /api/1/player   => Fetch
PUT     => /api/1/player   => Update
```

This route system needs to have a resource with `id == 1` in your actual DB before startup time to work.

If you don't have a `config.schema` property set in your `Resource`, it will create one for you at startup time.

Else, `Nodulator` will throw an error and shutdown.

If you use `SqlMem` DB system, you must add a 'default' value to each resource fields in order to add it at startup.


#### Multi Route Object

Nodulator provides also a standard route system for lazy : `Nodulator.Route.MultiRoute`.
It allows you to handle your resources like its a big collection.
 It setups 5 routes (exemple when attached to a `PlayerResource`) :

```
GET     => /api/1/players       => List
POST    => /api/1/players       => Create
GET     => /api/1/players/:id   => Get One
PUT     => /api/1/players/:id   => Update
DELETE  => /api/1/players/:id   => Delete
```

#### Route Inheritance

You can inherit from any route object :

```coffeescript
class Test1Route extends Nodulator.Route
class Test2Route extends Nodulator.Route.DefaultRoute
class Test3Route extends Test2Route
class Test4Route extends Test3Route
```
And you can override existing route by providing same association verb + url. Exemple :

```coffeescript
class TestRoute extends Nodulator.Route.DefaultRoute
  Config: ->
    super()

    # Here we override the default GET => /api/1/{resource_name}/:id
    @Get '/:id', (req, res) =>
      [...]
```

___
## Db Systems

#### Abstraction

We defined a driver interface for some DB implementations.

It's based on SQL `Table` concept. (see [lib/connectors/sql/index.coffee](https://github.com/Champii/Nodulator/blob/master/lib/connectors/sql/index.coffee))

```coffeescript
Table.Find(id, done)
Table.FindWhere(fields, where, done)
Table.Select(fields, where, options, done)
Table.Save(blob, done)
Table.Insert(blob, done)
Table.Update(blob, where, done)
Table.Delete(id, done)
```

Every `Resource` have an associated `Table` instance that links to the good table/document in the good DB driver system

#### Mysql

Built-in `MySQL` implementation ([node-mysql](https://github.com/felixge/node-mysql/)) for `Nodulator`

Check [lib/connectors/sql/Mysql.coffee](https://github.com/Champii/Nodulator/blob/master/lib/connectors/sql/Mysql.coffee)

#### MongoDB

Built-in `MongoDB` implementation ([mongous](https://github.com/amark/mongous)) for `Nodulator`

Check [lib/connectors/sql/Mongo.coffee](https://github.com/Champii/Nodulator/blob/master/lib/connectors/sql/Mongo.coffee)

#### SqlMem

Special DB driver, built on RAM.

It provides same options as others systems do, but nothing is stored. When you stop the server, everything is deleted.

Check [lib/connectors/sql/SqlMem.coffee](https://github.com/Champii/Nodulator/blob/master/lib/connectors/sql/SqlMem.coffee)

___
## Other stuff

#### Bus

There is a `Nodulator.bus` object that is basicaly an `EventEmitter`. Every objects in `Nodulator` use this bus.

Here are the emitted events:

- On a new `Resource` being inserted in DB, sends it after a `Serialize()` call
  - `Nodulator.bus.emit 'new_' + resource_name, @Serialize()`

- On a `Resource` being updated in DB, sends it after a `Serialize()` call
  - `Nodulator.bus.emit 'update_' + resource_name, @Serialize()`

- On a `Resource` being deleted from DB, sends it after a `Serialize()` call
  - `Nodulator.bus.emit 'delete_' + resource_name, @Serialize()`

Exemple

```coffeescript
PlayerResource = Nodulator.Resource 'player'

Nodulator.on 'new_player', (player) ->
  [...] # Do something with this brand new player
```

You can override default `Bus` by setting new class to Nodulator.Bus :

```coffeescript
Nodulator = require 'nodulator'
NewBus = require './NewBus'

Nodulator.Bus = NewBus
```

Always set new `Bus` before any new `Resource` call or any added `Module`

___
## Modules

#### Usage

To inject a module into `Nodulator`, preceed this way :

```coffeescript
Nodulator = require 'nodulator'
ModuleName = require 'nodulator-ModuleName'

Nodulator.Use ModuleName
```

Replace `ModuleName` with the module's name you want to load

#### Module Hacking

If you want to create a new module for `Nodulator`, you have to export a single function, taking `Nodulator` as parameter :

```coffeescript
module.exports = (Nodulator) ->
  [...] # Your module here
```

You can extend anything you want, as the whole `Nodulator` object is passed to your function.

Be carefull to `server/loadOrder.json`.

Watch how [other modules](#compatible-modules-and-dependencies) are made !

___
## Project Generation
You can get global `Nodulator` :

```
$> npm install -g nodulator
$> Nodulator
Usage: Nodulator (init) | ((install |  install-dev | remove) moduleName1 [, moduleName2 [, ...]])
```

Nodulator provides a way of installing `Nodulator`, modules and dependencies easely
```
# If no arguments, install or remove Nodulator
$> Nodulator install
$> Nodulator install-dev
$> Nodulator remove

# Will install nodulator-angular and every dependencies (if any)
$> Nodulator install angular

# Will install nodulator-angular, nodulator-account, and all their dependencies (if any)
$> Nodulator install angular account

# Will create local link instead of a full install of nodulator-angular and every dependencies (if any)
# It's used to avoid reinstalling locally a Nodulator package under development
$> Nodulator install-dev angular

# Will remove nodulator-socket
$> Nodulator remove socket
```

Then you can launch the `init` process :
```
$> Nodulator init
```

It creates the following structure if non-existant :
```
main.coffee
package.json
settings/
server/
├── index.coffee
├── loadOrder.json
├── processors/
│   └── index.coffee
└── resources/
    └── index.coffee
```

And then find for every `Nodulator` modules installed, and call their respective `init` method.

It generate a `main.coffee` and a `package.json` with every modules pre-loaded.

The `server` folder is auto-loaded (check `server/index.coffee` and every `index.coffee` in subfolders).

Folders load order is defined in `server/loadOrder.json`, and is automaticaly managed by new modules installed (they care of the order)

You can immediately start to write `Resource` in `server/resources` !

___
## Developers

Never forget that I'm always available at contact@champii.io for any questions (Job related or not ;-)

___
## Contributors

- [Champii](https://github.com/champii)
- [SkinyMonkey](https://github.com/skinymonkey)

<!-- ___
## DOC

```
Nodulator

  Properties :
    Nodulator.app       => the express app
    Nodulator.express   => the express module
    Nodulator.passport  => the passport module
    Nodulator.server    => the http server
    Nodulator.authApp   => if this app handle passport authentication
    Nodulator.appRoot   => the app root path
    Nodulator.bus       => official bus (EventEmitter)
    Nodulator.Route     => Route object

  Nodulator.Resource(resourceName, [Route], [config])

    Create the resource Class

  Nodulator.Config(config)

    Change config

  Nodulator.Use(module)

    Inject a module inside Nodulator

  Nodulator._ListEndpoints(done)

    DEBUG PURPOSE
    List every api endpoint added by application

Resource

(Uppercase for Class, lowercase for instance)

  Resource.Fetch(id, done)

    Take an id and return it from the DB in done callback: (err, resource) ->

  Resource.FetchBy(constraints, done)

    Take an object representing contraints, and return first row from the DB in done callback: (err, resource) ->

  Resource.List(done)

    Return every records in DB for this resource and give them to done: (err, resources) ->

  Resource.ListBy(constraints, done)

    Take an object representing constraints, and return every row from the DB in done callback: (err, resources) ->

  Resource.Deserialize(blob, done)

    Method that take the blob returned from DB to make a new instance

  Resource.Create(blob, done)

    Alias for Deserialize and Save

  resource.Save(done)

    Save the instance in DB

    If the resource doesn't exists, it create and give it an id
    It return to done the current instance


  resource.Delete(done)

    Delete the record in DB, and return affected rows in done

  resource.Serialize()

    Return every properties defined in the schema,
    else if no schema is defined it will take every properties not stating with '_' (the private ones)
    This method is used to get what must be saved in DB

  resource.ToJSON()

    This method is used to get what must be send to client
    Call @Serialize() by default, but can be overrided

Route

  route.Get     [url = ''], [middleware, [middleware, [...]]], done)
  route.All     [url = ''], [middleware, [middleware, [...]]], done)
  route.Post    [url = ''], [middleware, [middleware, [...]]], done)
  route.Put     [url = ''], [middleware, [middleware, [...]]], done)
  route.Delete  [url = ''], [middleware, [middleware, [...]]], done)

    Create a route.

    'url' will be concatenated with '/api/{VERSION}/{RESOURCE_NAME}'. Optional
    'middleware' are optionals
    'done' is the express app callback: (req, res, next) ->

  route.Config()

    Called when a Route is associated with a Resource.
    This call prepare every routes, and must be inherited.

``` -->

___
## ToDo

By order of priority

- Better tests
- Tests for validation
- Tests for model association
- Better error management
- Log system
- Abstract class can retrieve every child `Resource`
- Remove an existing route
- Type inference in schema for default field
- Route instanciation without resources


___
## ChangeLog
XX/XX/XX: current (not released yet)
  - Added `SingleRoute` object, for manipulating Singleton `Resource`
  - Removed `req.instances` from every `Route`
  - Added tests for `SingleRoute`
  - Route proxy methods for `@_All()` are now generated at runtime
  - Renamed `DefaultRoute` to `MultiRoute`
  - Added a `default` field to config schema
  - `Resource.Init()` now returns the `Resource` itself, for chaining purpose.
  - Added tests for resource association
  - Tests are now executed in specific order
  - You can now give an array as schema type for a field, in order to retrive multiple resources based on id
  - Added Javascript support
  - Added an output line to tell the user when the framework is listening and to which port
  - Fetch and Create can now take one argument or an array of arguments
  - Fixed bugs on resource association:
    - ToJSON() now call child ToJSON() instead of Serialize()
    - ToJSON() call check if given association exists
  - Added 'distantKey' in relational schema to fetch relation that have that resource id as given key
  - Added maxDepth field to resource config in order to limit the relationnal fetch. There is also a Resource.DEFAULT_DEPTH constant that is used when nothing is precised.
  - Added argument to Resource.Init(): You can give the config object in order to avoid recursive require when two way model association
  - Removed Doc section. It will be on the website documentation.
  - Code in Init() has been splited for code clarity

04/05/15: v0.0.18
  - You can specify a 'store' general config property in order to switch to redis-based sessions

03/05/15: v0.0.17
  - You can now specify a property type in schema without wrapping it in a object like {type: "string"}

15/04/15: v0.0.16
  - Removed redis references for sessions

14/04/15: v0.0.15
  - Minor changes in `Route` to fit [Nodulator-Account](https://github.com/Champii/Nodulator-Account) new release

10/04/15: v0.0.14
  - Resource 'user' is no longer a reserved word
  - Resources with name finishing with 'y' are now correctly put in plurial form in route name

09/04/15: v0.0.13
  - Better model association and validation
  - Pre-fetched resources in `Route.All()` are now put in `@instance` instead of `req[@resource.lname]`
  - Updated README
  - Updated Mongo driver

20/01/15: v0.0.12
  - Fixed bug on FetchBy

20/01/15: v0.0.11
  - Fixed tests
  - Added travis support for tests
  - Added model associations
  - Added schema and model validation
  - Changed `FetchBy` and `ListBy` prototype. Now take an object instead of a key/value pair.
  - Added `Create()` method into `Resource`
  - Added `limit` and `offset` to both Mysql and SqlMem

07/01/15: v0.0.10
  - Added Philosophy section
  - Added multiple package name support in package generation
  - Fixed some bugs with modules

03/01/15: v0.0.9
  - Separated `AccountResource` into a new module [Nodulator-Account](https://github.com/Champii/Nodulator-Account)
  - Changed README

02/01/15: v0.0.8
  - Fixed Route middleware issue

02/01/15: v0.0.7
  - Separated `Socket` into a new module [Nodulator-Socket](https://github.com/Champii/Nodulator-Socket)
  - Added new methods for `@Get()`, `@Post()`, `@Delete()`, `@Put()`, `@All()` in `Route`
  - Replace old method `@All()` into `@_All()`. Is now a private call.
  - Improved README (added [Modules](#modules) section)
  - Global `Nodulator` now manage dependencies installation
