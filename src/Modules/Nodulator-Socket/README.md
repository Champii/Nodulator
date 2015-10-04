Nodulator-Socket
================

Socket.io module implementation for [Nodulator](https://github.com/Champii/Nodulator)

Master : [![Build Status](https://travis-ci.org/Champii/Nodulator-Socket.svg?branch=master)](https://travis-ci.org/Champii/Nodulator-Socket)

Develop: [![Build Status](https://travis-ci.org/Champii/Nodulator-Socket.svg?branch=develop)](https://travis-ci.org/Champii/Nodulator-Socket)

NPM: [![npm version](https://badge.fury.io/js/nodulator-socket.svg)](http://badge.fury.io/js/nodulator-socket)

Released under [GPLv2](https://github.com/Champii/Nodulator-Socket/blob/master/LICENSE.txt)


## Concept

Provides server-side `socket.io` implementation for `Nodulator`

___
## Features

- General implementation for `socket.io`
- Room system
- Link with `passport` session

___
## JumpTo

- [Installation](#installation)
- [Basics](#basics)
- [Rooms](#rooms)
- [Project Generation](#project-generation)
- [TODO](#todo)
- [Changelog](#changelog)

___
## Installation

You can automaticaly install `Nodulator` and `Nodulator-Socket` by running

```
$> sudo npm install -g Nodulator
$> Nodulator install socket
```

Or you can just run `npm` :

```
$> npm install nodulator nodulator-socket
```

___
## Basics

```coffeescript
Nodulator = require 'nodulator'
Socket = require 'nodulator-socket'

Nodulator.Use Socket
```

It adds `Nodulator.Socket()` function that you can extend

This interface provides 2 methods to override :
- `@OnConnect(socket)`
- `@OnDisconnect(socket)`

```coffeescript
Nodulator = require 'nodulator'

class Socket extends Nodulator.Socket()

  OnConnect: (socket) ->
    console.log 'Socket connected: ', socket

Socket.Init()

module.exports = Socket
```

___
## Rooms

Each time a `Resource` is initialized, it create a new room and place each new connecting sockets into it.

Then it listen for every `Resource` events (new_{resource_name}, update_{resource_name}, delete_{resource_name}) and broadcast theses to the attached room (and so to each sockets)

(See [Nodulator Bus](https://github.com/Champii/Nodulator#bus))

___
## Project Generation

See [Nodulator's project generation](https://github.com/Champii/Nodulator#project-generation)

When calling `$> Nodulator init`, it will automaticaly create following structure if non-existant:

```
server
└─ sockets
  └─ index.coffee
```

The `index.coffee` file is a pre-extended `Nodulator.Socket()` class

___
## TODO

- Repair passport session and socket.io match system (passportSocketIO)
- Provide a filter to apply permissions on specific resource room
- Make sockets private channel and give them only user-related content instead of every event

___
## Changelog

XX/XX/15: current
  - Added redis as default store for sessions


03/01/15: v0.0.3
  - passport.socketio isnt loaded anymore if [Nodulator-Account](https://github.com/Champii/Nodulator-Account) module is missing.

02/01/15: v0.0.2
  - Improved README

30/12/14: v0.0.1
  - Initial commit
