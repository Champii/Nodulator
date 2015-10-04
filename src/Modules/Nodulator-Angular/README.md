Nodulator-Angular
=================

AngularJS implementation and facilities for Nodulator.

Needs:
- [Nodulator](https://github.com/Champii/Nodulator)
- [Nodulator-Assets](https://github.com/Champii/Nodulator-Assets)
- [Nodulator-Socket](https://github.com/Champii/Nodulator-Socket)

Released under [GPLv2](https://github.com/Champii/Nodulator-Angular/blob/master/LICENSE.txt)

## Concept

Provides class for `angular`'s directives, services, controllers and factories.
Allow inheritance of `angular` behaviour, and automatic link between services and `Nodulator.Resources` thanks to `Nodulator-Socket` (socket-io)

___
## Features

- Automatic ResourceService instantiated for each Resources on server
- Automatic directive creation on template
- Give CoffeeScript style classes for each `angular` functions
- `Socket-io` implementation for `angular`
- `Nodulator.ResourceService` to link `Nodulator.Resource` to `angular` as a service
- Automatic adding of views as templates
- Automatic link between directives and templates (template file must have same name as directive)
- Automatic appending of `ng-app="app"` to `body` tag

___
## JumpTo

- [Installation](#installation)
- [Basics](#basics)
- [Client Side](#client Side)
  - [Base](#base)
    - [Services](#services)
    - [Directives](#directives)
    - [Factories](#factories)
    - [Controllers](#controllers)
  - [Extended](#extended)
    - [Socket](#socket)
    - [ResourceService](#resourceservice)
- [Coding Rules](#codingrules)
- [Project Generation](#project-generation)
- [TODO](#todo)
- [Changelog](#changelog)

___
## Installation

You can automaticaly install `Nodulator`, `Nodulator-Angular` and every dependencies by running

```
$> sudo npm install -g Nodulator
$> Nodulator install angular
```

Or you can just run `npm` :

```
$> npm install nodulator nodulator-assets nodulator-socket nodulator-angular
```
___
## Basics

```coffeescript
    Nodulator = require 'nodulator'
    Socket = require 'nodulator-socket'
    Assets = require 'nodulator-assets'
    Angular = require 'nodulator-angular'

    # Default config, can be omited
    Nodulator.Config
      servicesPath: '/client/services'
      directivesPath: '/client/directives'
      controllersPath: '/client/controllers'
      factoriesPath: '/client/factories'
      templatesPath: '/client/views'

    # Required for Angular module to work
    Nodulator.Use Socket

    Nodulator.Use Assets

    Nodulator.Use Angular

    Nodulator.Run()
```

When main page is loaded, main `Nodulator` scripts adds `ng-app="app"` to `body` tag in order to initialize `angular` application.

___
## Client side

### Base

#### Services

Services can be created easely. First `Nodulator.Service()` argument is the service name.
Nodulator will append 'Service' at the end of this name.
For a service name 'test', its real name will be 'testService'
Latter arguments are for dependency injection. Each one will be added to class :

```coffeescript
    class TestService extends Nodulator.Service 'test', '$http'

      Test: ->
        console.log 'Test'
        @$http.get(...);

    #Init only if you want to actualy create the service.
    #Omit if you only want to inherit from it.
    TestService.Init()
```

#### Directives

Again, first argument is the directive name, and the latters are for dependencies injections.
By default, every directive is `{restrict: 'E'}`. You can override or add properties by passing an object somewhere in the dependencies list.

For directive `test`, it will look for template in `config.viewPath` for file of same name (`test.jade` for exemple)

The context of the class will be attached to `angular` `scope`. This way, the following directive...

```coffeescript
    class TestDirective extends Nodulator.Directive 'test', 'testService'

      foo: 'bar'

      Foo: ->
        @foo = 'bar2'
        @testService.Test()

    TestDirective.Init()
```

... become ...

```coffeescript
    app.directive 'test', ['testService', (testService) ->
      return {

        restrict: 'E'

        templateUrl: 'test-tpl'

        link: (scope, element, attrs) ->

          scope.testService = testService

          scope.foo = 'bar'

          scope.Foo = ->
            scope.foo = 'bar2'
            scope.testService.Test()

      }
    ]
```

Nice uh ?
Beware, don't put to many things ~~in your sister~~ in the injections, they will all be injected in the scope ! (You probably don't want this, and a solution is currently in the pipe.)

You can also use `compile` instead of `link` by defining a `@Pre()` and/or a `@Post()` method.

```coffeescript
    class TestDirective extends Nodulator.Directive 'test'

      Pre: ->
        @name = 'test'

      Post: ->
        @foo = ''

        @test = ->
            @foo = 'bar'

    TestDirective.Init()
```

#### Factories

Just as Services, factories are easy to declare :

```coffeescript
    class TestFactory extends Nodulator.Factory 'test', '$http'

      Test: ->
        console.log 'Test'
        @$http.get(...);

    TestFactory.Init()
```

#### Controllers

Just like directives, Controllers have their context binded to the $scope.

```coffeescript
    class TestController extends Nodulator.Controller 'test', '$http'

      foo: 'bar'

      Test: ->
        console.log 'Test'
        @foo = 'bar2'

    TestFactory.Init()
```

___
### Extended

#### Socket

A socket is a `Nodulator.Factory` implementing `Socket.io`
For the moment, a socket is always instanciated in each project. Future configuration will be disponible.

A socket has 2 methods : `@On()` and `@Emit()`, and apply changes to scope automaticaly.

#### ResourceService

A `Nodulator.ResourceService` inherits from `Nodulator.Service` and inject automatically `$http` and `socket`.
Also, it binds the socket to listen to the server `Resource` with the same name.
It provides 5 methods :

```coffeescript
    class TestService extends Nodulator.ResourceService 'test'

        OnNew: (item) ->
          # Called when a new resource instance is created

        OnUpdate: (item) ->
          # When a resource instance is updated

        OnDelete: (item) ->
          # When a resource is deleted

        List: (done) ->
          # Put every records in @list

        Fetch: (id, done) ->
          # Fetch particular model and put it in @current

        Delete: (id, done) ->
        Add: (blob, done) ->
        Update: (blob, done) ->
```

___
### Coding Rules

One directive by file. This is important for the automatic directive creation based on template.


___
### Project Generation

By calling `$> Nodulator init` with this module installed,

It creates the following structure if non-existant:
```
client
├── controllers
├── directives
├── factories
├── index.coffee
├── services
└── views
```

And it gets `AngularJS` from official website and puts it in `/client/public/js`

___
## TODO

- Nodulator-Backoffice ?
- Find a way to don't attach `angular` object ($http, $rootScope,...) to local directive `scope`
- Remove socket.io hard essential link, and make it more modular.

___
## Changelog

XX/XX/15: current
  - Added capacity to override default Directive parameters
  - Removed reference to UnderscoreJS
  - InjectViews is now called from assets to fit invoked site
  - Adaptation to work with the new 'site' functionality from Assets
  - Auto added missing directive for given template
  - Auto added missing resource service for given resource when invoked

15/02/15: v0.0.10
  - Added Controller

07/01/15: v0.0.9
  - Fixed bug in project generation

03/01/15: v0.0.8
  - Updated README

02/01/15: v0.0.7
  - Updated `exemples/todo`

02/01/15: v0.0.6
  - Improved README
  - Added `ng-app="app"` to `body` tag
  - Adapted to `Nodulator-Assets` change
