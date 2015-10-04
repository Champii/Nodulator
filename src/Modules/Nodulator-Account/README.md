Nodulator-Account
=================

Master : [![Build Status](https://travis-ci.org/Champii/Nodulator-Account.svg?branch=master)](https://travis-ci.org/Champii/Nodulator-Account)

Develop: [![Build Status](https://travis-ci.org/Champii/Nodulator-Account.svg?branch=develop)](https://travis-ci.org/Champii/Nodulator-Account)

NPM: [![npm version](https://badge.fury.io/js/nodulator-account.svg)](http://badge.fury.io/js/nodulator-account)

Released under [GPLv2](https://github.com/Champii/Nodulator-Account/blob/master/LICENSE.txt)

##### Under heavy development

___
## Concept

Provides ability to [Nodulator](https://github.com/Champii/Nodulator) to manage authentication, sessions and route permissions.

___
## Features

- Basic mail authentication
- Session management over Redis
- File generation for login/signup views/directive for [Nodulator-Angular](https://github.com/Champii/Nodulator-Angular)
- File generation for Server side `AccountResource`
- Permission system

___
## JumpTo

- [Installation](#installation)
- [Basics](#basics)
- [AccountResource](#accountresource)
- [Permissions](#permissions)
- [Project Generation](#project-generation)
- [TODO](#todo)
- [Changelog](#changelog)

___
## Installation

You can automaticaly install `Nodulator` and `Nodulator-Account` by running

```
$> sudo npm install -g Nodulator
$> Nodulator install account
```

Or you can just run `npm` :

```
$> npm install nodulator nodulator-account
```

___
## Basics

```coffeescript
Nodulator = require 'nodulator'
Account = require 'nodulator-account'

Nodulator.Use Account
```

___
## AccountResource

This module provides `Nodulator.AccountResource` that extends `Nodulator.Resource` and deals with every parts of app authentication.

Authentication is based on Passport

```coffeescript
class PlayerResource extends Nodulator.AccountResource 'player'
```

Defaults fields for authentication are `'username'` and `'password'`

You can change them (optional) :

```coffeescript
config =
  fields:
    usernameField: 'login'
    passwordField: 'pass'

class PlayerManager extends Nodulator.AccountResource 'player', config
```

The passwordField of an AccountResource is never returned by the .ToJSON() method for evident security reasons.

It creates a custom method from `usernameField`

```
*FetchByUsername(username, done)

  or here if customized

*FetchByLogin(login, done)

* Class methods
```

It defines 2 routes (here when attached to a `PlayerResource`) :

```
POST   => /api/1/players/login
POST   => /api/1/players/logout
```

It setup session system, and thanks to Passport,

It fills `req.user` variable to handle public/authenticated routes

You have to `extend` yourself the `post` default route (for exemple) of your `AccountResource` to use it as a signup route.

___
## Permissions

There is two ways to deal with permissions: You can restrict a whole object:

```coffeescript
config =
  restrict: Nodulator.Route.Auth()

class TestResource extends Nodulator.Resource 'test', Nodulator.Route, config

```

And/or a single API call (see exemples below)


The `Route` object exposes 3 middleware to manage permissions :

#### Nodulator.Route.Auth()

This middleware checks if the current user is logged in, or returns a 403 forbidden if not.

```coffeescript
class TestRoute extends Nodulator.Route
  Config: ->
    super()

    #You have shorcuts for every perission call
    #made inside a Route. (here: @Auth())
    @Get @Auth(), (req, res) =>
      [...]
      # This call will be executed only if user is logged
```

#### Nodulator.Route.HasProperty(object)

This middleware checks if the current user is logged in and have the specified properties set

```coffeescript
class TestRoute extends Nodulator.Route
  Config: ->
    super()

    @Get @HasProperty({group_id: 2}), (req, res) =>
      [...]
      # This call will be executed only if user is logged
      # and have the property group_id set to '2'
```

#### Nodulator.Route.IsOwn(string)

This middleware checks if the current user is logged in and the route param specified is own user.id

```coffeescript
class TestRoute extends Nodulator.Route
  Config: ->
    super()

    @Get '/:player_id', @IsOwn('player_id'), (req, res) =>
      [...]
      # This call will be executed only if user is logged
      # and have (user.id === req.params.player_id)
```
#### SelfMade permissions

You can make your own permissions using the express middleware system.
Your function must take (req, res, next) ->, or return a function that takes these parameters.
Please refer to the express documentation if you don't know what a middleware is.

___
## Project Generation

See [Nodulator's project generation](https://github.com/Champii/Nodulator#project-generation)

When calling `$> Nodulator init`, it will automaticaly create following structure if non-existant:

```
/
└─ server/
   └─ resources/
      └─ ClientResource.coffee
```

If [Nodulator-Angular](https://github.com/Champii/Nodulator-Angular) is installed, it also create this structure :

```
/
└─ client/
   ├─ auth.jade
   ├─ directives/
   │  └─ AuthDirective.coffee
   ├─ services/
   │  └─ UserService.coffee
   └─ views/
      └─ auth.jade
```

This structure contains a directive/view pair for asking user to login/signup,
a UserService to manage client-side session, and a global auth.jade view to render.

If no `Nodulator-Angular` module is found, but a [Nodulator-Assets](https://github.com/Champii/Nodulator-Assets) is, a simple `client/auth.jade` file is added to handle basic authentication.

___
## TODO

- Better test suite
- Social signup

___
## Changelog

XX/XX/XX: current (not released yet)
  - Fixed error in package generation, when Init, it never add support for angular or raw client
  - Login and Logout callbacks now take req instead of req.user

03/05/15: v0.0.7
  - Fixed bad 403 when `IsOwn(key)` is used on a route without the given key in params
  - Fixed req.user undefined when used in a Resource defined before AccountResource
  - Tests

14/04/15: v0.0.6
  - Adding `Nodulator.Route.Auth()` permission call
  - Adding `Nodulator.Route.HasProperty(object)` permission call
  - Adding `Nodulator.Route.IsOwn(string)` permission call
  - You can add permissions on certains api call or on a whole `Route` object (config.restrict)
  - Added unit tests for basic auth and permissions

10/04/15: v0.0.5
  - The userField.passwordField of .ToJSON() is not returned anymore
  - Fixed generation problem with no nodulator-assets included
  - Different generation if `Nodulator-Angular`, `Nodulator-Assets`, both or none of them

20/01/15: v0.0.4
  - Fixed bugs about `@_table`

20/01/15: v0.0.3
  - Fixed bugs

03/01/15: v0.0.2
  - Fixed bug on auth when custom userFields

03/01/15: v0.0.1
  - Initial release
