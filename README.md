     _   _           _       _       _
    | \ | | ___   __| |_   _| | __ _| |_ ___  _ __
    |  \| |/ _ \ / _` | | | | |/ _` | __/ _ \| '__|
    | |\  | (_) | (_| | |_| | | (_| | || (_) | |
    |_| \_|\___/ \__,_|\__,_|_|\__,_|\__\___/|_|   V0.1.5

[![Coverage Status](https://coveralls.io/repos/github/Champii/Nodulator/badge.svg?branch=master)](https://coveralls.io/github/Champii/Nodulator?branch=master)
[![Build Status](https://travis-ci.org/Champii/Nodulator.svg?branch=master)](https://travis-ci.org/Champii/Nodulator) (Master)

[![Build Status](https://travis-ci.org/Champii/Nodulator.svg?branch=develop)](https://travis-ci.org/Champii/Nodulator) (Develop)

[![NPM](https://nodei.co/npm/nodulator.png?downloads=true&downloadRank=true&stars=true)](https://nodei.co/npm/nodulator/)

[![NPM](https://nodei.co/npm-dl/nodulator.png?months=1)](https://nodei.co/npm/nodulator/)

##### Under heavy development

___
## Concept

`Nodulator` is designed to make it more easy to build highly modulable
applications with REST APIs and with integrated ORM.

You must understand [express](https://github.com/strongloop/express) basics for routing

Open [exemples](https://github.com/Champii/Nodulator/blob/master/exemples)
folder to see a full working exemple in JavaScript, CoffeeScript and LiveScript.

Released under [GPLv2](https://github.com/Champii/Nodulator/blob/master/LICENSE.txt)

Written in [LiveScript](http://livescript.net/)

#### Documentation at [http://nodulator.champii.io](http://nodulator.champii.io)

___
## Jump To

- [Features](#features)
- [Installation](#installation)
- [Compatible modules](#compatible-modules)
- [Philosophy](#philosophy)
- [Developers](#developers)
- [Contributors](#contributors)
- [TODO](#todo)
- [Changelog](#changelog)

___
## Features

- [LiveScript](http://livescript.net/)
- Integrated ORM
- Integrated Routing system (with express, and highly linked with ORM)
- Multiple DB Systems
- Complex inheritance system
- Chainable async calls
- Modulable
- Project generation
- Cache
- Schema-less/Schema-full models
- Model validation
- Model association (rails style) and automatic retrieval
- Models and associations over different DB systems
- Reactive values [Hacktiv](https://github.com/Champii/Hacktiv)
- Promises or Callbacks
- Log and Debug system
- Console mode

___
## Installation

Just run :
```
npm install nodulator
```
Or check the [Project Generation](#project-generation) section

After you can require `Nodulator` as a module :

```javascript
var N = require('nodulator');
```

___
### Compatible modules

- [Nodulator-Assets](https://github.com/Champii/Nodulator/tree/master/src/Modules/Nodulator-Assets):
  - Automatic assets management
- [Nodulator-Socket](https://github.com/Champii/Nodulator/tree/master/src/Modules/Nodulator-Socket):
  - Socket.io implementation for Nodulator
- [Nodulator-Angular](https://github.com/Champii/Nodulator/tree/master/src/Modules/Nodulator-Angular):
  - Angular implementation for Nodulator
  - Inheritance system
  - Integrated and linked SocketIO
  - Assets management
- [Nodulator-Account](https://github.com/Champii/Nodulator/tree/master/src/Modules/Nodulator-Account):
  - Authentication with passport
  - Permissions management
  - Sessions
  - Nodulator-Angular integration

___
## Philosophy

`Nodulator` is a project that is trying to make a big overlay to every
traditional packages used to make REST client/server applications in Javascript/CoffeeScript/LiveScript/...

Its main goal is to give developers a complex REST routing system, an ORM and
high-level modules, encapsulating every classic behaviour needed to create
complex projects.

Its core provides everything needed to build powerful and highly modulable
REST APIs, and allow the developer to reuse his code through every projects.

___
## Developers

I'm always available at contact@champii.io for any questions
 (Job related or not ;-)

___
## Contributors

- [Champii](https://github.com/champii)
- [SkinyMonkey](https://github.com/skinymonkey)

___
## ToDo

By order of priority

- Fix bug when using Add() on MayHasOne relationship that is already linked: no replacement for the child id so two references coexist simultaneously
- Bind Route 'this' to Resource by default, and rename SetInstance to BindThis to change it (to an instance for exemple)
- Customise error codes in Route
- Paginated Resource
- When cache expire, remove correspondant Watcher /!\
- Better query on Resource (gt, gte, lt, lte, not, range, ...)
- Migration system
- Auto wrap new methods in `Resource`
- Association Polymorphism
- Watch a specific field
- Relations not only based on id but on every property types
- Persistant sessions in Console
- 0bject OwnRoute that perform from logged user (/api/1/player or /api/1/tasks for exemple)
- Scaling (cluster, distributed bus)
- List return a resource that can act on each item (Set, Add, ...) ( Extend Array ? )
- Better tests
  - Request
  - Multi Driver fetch/list
  - Db
    - SqlMem
    - Mysql
    - Mongo
    - Ids
    - HABTM tables
  - Cache
  - Config oveloading
  - Schema
    - HasOneThrough
    - HasManyThrough

___
## ChangeLog
XX/XX/XX: current (not released yet)
  - Isomorphic view system (NView)
    - The whole project has been abstracted and subdivided into common, client and server folder
    - The client part of the project is sent to the client, helpers available, isomorphic API
    - Added ClientDB that is replicated-on-the-fly from the server db into the client. It implements events to notify other parts of the program, and a sort of prediction system that revert changes if server reply gone wrong.
    - Home-made React-like dom manipulation system (Lived)
      - Render system that take a view
      - View system: functions that return a node, can be nested
      - Shadow-dom that handle node change and propagate to real dom
        - Node Watchers (Hacktiv)
        - Allow to reference the dom inside of itself (node = input type: text)
        - Events bindings (click and change for the moment)
      - Bindings to Resources as a Route
        - Activate RPC based Routes
        - Allow to attach a View to an Resource. Doing so allow to use a Promise or a Resource instance directly inside a View. Will reload the node when the data is ready or change.

  -  Better module system and configuration
    - PostConfig for modules
    - Modules are now correctly preinstalled with N binary
    - NModule abstract class to handle pre/post configuration process
    - Rework of NAssets
      - Manage more than one site with one or more mountpoints
      - Language preprocessors (Livescript/Coffeescript)
      - Grunt tasks to compile/minify for production mode (when {minified: true})
      - Default client root is now the root of the project. Configuration available

  - Launcher wrapper to handle every Nodulator early and late modules work  
  - Better binary helper and usage
  - Better cache configuration
  - Removed fliped done parameters (useless)
  - Better general configuration
  - Removed ugly '@.__proto__.constructor.* ' from Resource ctor, using prototype inheritance for that
  - Better Watch system for Resource class (all, new, updated, deleted)
  - Added '@_type' property for reflexivity (replaced '@lname')
  - Better limit and sortBy
  - Added tests for
    - Resource
    - HasAndBelongsToMany
    - Promises

01/12/15: 0.1.5
  - Added Unique() property
  - Now you can throw inside a route to send an error
  - You can remove an existing route by declaring the same Verb + Url and returning null.
  - Renamed 'MultiRoute' into 'Collection'

30/11/15: 0.1.2
  - Fixed a bug for Add() on 'local' association
  - Updated exemples
  - package.json is cleaner
  - Fixed a bug with symlink on N
  - Fixed init and console

28/11/15: 0.1.0
  - LiveScript ! \o/
  - Lib Folder reorganisation
  - Added benchmarks folder
  - Replaced @instance in Route by req._instance.
  - Added a Request class to handle Resource in Route
  - The Route class can take a Resource as property. Also, Routes can be Instanciated.
  - Changed every 'Nodulator' call by 'N', more readable
  - Added a debug system with 'debug'
  - Console mode to "connect" to an existing/running Nodulator instance and perform standard calls
  - Joined Every modules into this git repo for a stronger compatibility
  - Shortcut the N.Resource() into a simple N()
  - Added a 'Watch' for both Instance and Class of Resource, that allow more flexibility
  - Added a virtual field filled when the resource is.
  - Added HasOne, HasMany, BelongsTo and BelongsToMany calls. Buggy at the moment and not standard
  - Added _WrapDebug() Wrapper
  - Web server now starts only when needed (when first Route is being declared)
  - Fixed validation fails
  - Added _CreateUnwrapped
  - Added a instance.Watch() call, to make the instance to auto-update when part of it change
  - Schema 'strict' or 'free'
  - When in Association, if the localKey doesnt exists, it is created on the fly
  - Better HasOne, HasMany and BelongsTo.
  - HasOneThrough, HasManyThrough
  - HasAndBelongsToMany
  - Resources can override global db config to put different models on different db systems
  - Resource instance can be created on different db than default
  - Added Cache over Redis
  - Added @Hydrate() function to populate properties and associations from cache
  - Added configuration for cache
  - Better configuration for db
  - Internal driver is now fixed to be the default Nodulator driver.
  - Globalized ids management by external table
  - internal_ids are now stored on default driver and are automaticaly updated with last Ids values
  - Chainable calls !
  - Create can now take a promise instead of an id
  - Better Remove() for MayHas*() associations
  - Schema is now inherited by copy
  - Internal() Field property that is not put in the JSON produced by ToJSON(), so not sent to any client but saved to DB anyway
  - JSON and object validation type
  - Each resource is available through N.Resourcename (exemple for 'player' : N.Player)
  - When a route is attached to a Resource, it is now available as Resource.Route

21/07/15: v0.0.19
  - Added `SingleRoute` object, for manipulating Singleton `Resource`
  - Removed `req.instances` from every `Route`
  - Added tests for `SingleRoute`
  - Route proxy methods for `@_All()` are now generated at runtime
  - Renamed `DefaultRoute` to `Collection`
  - Added a `default` field to config schema
  - `Resource.Init()` now returns the `Resource` itself, for chaining purpose.
  - Added tests for resource association
  - Tests are now executed in specific order
  - You can now give an array as schema type for a field, in order to retrive
  multiple resources based on id
  - Added Javascript support
  - Added an output line to tell the user when the framework is listening and
  to which port
  - Fetch and Create can now take one argument or an array of arguments
  - Fixed bugs on resource association:
    - ToJSON() now call child ToJSON() instead of Serialize()
    - ToJSON() call check if given association exists
  - Added 'distantKey' in relational schema to fetch relation that have that
  resource id as given key
  - Added maxDepth field to resource config in order to limit the relationnal
  fetch. There is also a Resource.DEFAULT_DEPTH constant that is used when nothing is precised.
  - Added argument to Resource.Init(): You can give the config object in order
  to avoid recursive require when two way model association
  - Removed Doc section. It will be on the website documentation.
  - Code in Init() has been splited for code clarity
  - Load order has changed between resources and socket
  - Added a @_type variable defining the typename of an instance
  - Fixed a bug in model association: no field in schema if array with no 'type'
  - Improved 'arrayOf' type check
  - Added function to default schema value (is that a possible virtual field ?)
  - Collection::Get() now can take query arguments
  - Added Resource::ExtendSafe() method to preserve associated models while extending a Resource
  - Modified Route::Collection and Route::SingleRoute to use Resource::ExtendSafe()
  - Removed app parameter from Route constructor
  - Route classes can now be instanciated without any Resources
  - Removed ListBy and FetchBy for simplicity
  - Resource::Deserialize() is now a private call : Resource::_Deserialize()
  - Removed the mandatory Init function call !
  - Added Promises if no callback given.
  - Routes are now instantiated when attached, not when Init. This helps the new lazy Init system
  - List can now take an array
  - Added Hacktiv support for Resources
  - Added a ChangeWatcher for Resources that watch for the result of a query to make change
  - You can now add a `flipDone: true` to the N.Config() call to have callback like (data, err) ->
  - Added Wrappers class to regroup every wrappers.
  - Added Wrappers for Promises, FlipDone, and for WatchArgs
  - Extend now dont need to be abstract to work
  - Added tests for promisesm FlipDone and reactive watching

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
  - Resources with name finishing with 'y' are now correctly put in plural form in route name

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
