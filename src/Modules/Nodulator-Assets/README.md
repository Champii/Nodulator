Nodulator-Assets
================

Assets and views automatic management system for [Nodulator](https://github.com/Champii/Nodulator)

Master : [![Build Status](https://travis-ci.org/Champii/Nodulator-Assets.svg?branch=master)](https://travis-ci.org/Champii/Nodulator)

Develop: [![Build Status](https://travis-ci.org/Champii/Nodulator-Assets.svg?branch=develop)](https://travis-ci.org/Champii/Nodulator)

NPM: [![npm version](https://badge.fury.io/js/nodulator-assets.svg)](http://badge.fury.io/js/nodulator-assets)

Released under [GPLv2](https://github.com/Champii/Nodulator-Assets/blob/master/LICENSE.txt)

## Concept

Provides ability to `Nodulator` to render views and auto-load assets in following folders:
- `Nodulator.config.js`: array for js (or coffee) files
- `Nodulator.config.css`: array for css files
- `Nodulator.config.viewRoot`: path for index.jade

___
## Features

- Automatic js and css assets loading
- Provides methods for modules to add folders to assets management
- Provides basic view system (only '`Nodulator.config.viewRoot`/index.jade' for the moment)
- Add a `Nodulator.Run()` method to be called last for view rendering
- Add a `Nodulator.ExtendBeforeRun()` and `Nodulator.ExtendAfterRun()` method for modules to add instructions at the begining of `Run()` or just before `Render()`
- Add a `Nodulator.ExtendBeforeRender()` and `Nodulator.ExtendAfterRender()` method for modules to add instructions at the begining of `Render()` or just before the actual `res.render()`
- CoffeeScript automatic compilation on fly
- Jade automatic compilation on fly (no other engines yet)
- Can manage multiple sites and assets collections

___
## JumpTo

- [Installation](#installation)
- [Basics](#basics)
- [Project Generation](#project-generation)
- [Module Hacking](#module-hacking)
- [TODO](#todo)
- [Changelog](#changelog)

___
## Installation

You can automaticaly install `Nodulator` and `Nodulator-Assets` by running

```
$> sudo npm install -g Nodulator
$> Nodulator install assets
```

Or you can just run `npm` :

```
$> npm install nodulator nodulator-assets
```

___
## Basics

```coffeescript
Nodulator = require 'nodulator'
Assets = require 'nodulator-assets'

# Default config, can be omited
Nodulator.Config
  assets:
    app: # You can add another entry like 'app' to handle another site
      path: '/client'
      js: ['/client/public/js/', '/client/']
      css: ['/client/public/css/']

  viewRoot: 'client'
  engine: 'jade' #FIXME: no other possible engine

Nodulator.Use Assets

# New method, to be called last for rendering
Nodulator.Run()
```

In `index.jade`, you must always call `| !{nodulator()}` at the end of the file.

It's there that all `Nodulator-Assets` magic stuff occur, and the only call you'll ever have to do in views.

___
## Project Generation

See [Nodulator's project generation](https://github.com/Champii/Nodulator#project-generation)

When calling `$> Nodulator init`, it will automaticaly create following structure if non-existant:

```
client
├── index.jade
└── public
    ├── css
    ├── img
    └── js
```

___
## Module Hacking

The module is stored in `Nodulator.assets` and provides following methods :

```coffeescript
  # Add folders given in list to assets list
  Nodulator.assets.AddFolder (list) ->

  # Add folders given in list to assets list, the recursive way
  Nodulator.assets.AddFolderRec (list) ->
```

Exemple of asset list : (paths are relative to project root)

```coffeescript
  list =
    '/js/app.js': ['/client/folder1/']
    '/css/app.css': ['/client/public/css/']
```

___
## TODO

- Test suite
- Image (and other static assets) management
- Split assets between `head` and `body` tags

___
## Changelog

XX/XX/XX: Current (not released yet)
  - Added a parameter to view nodulator() function to get a specific set of assets
  - Added multiple sites modification

12/02/15: v0.0.9
  - Added fake tests
  - Updated README

03/01/15: v0.0.8
  - Added `Nodulator.ExtendBeforeRender()` and `Nodulator.ExtendAfterRender()` to precisely extend render process.

02/01/15: v0.0.7
  - Updated README

02/01/15: v0.0.6
  - Changed `Nodulator.ExtendRunProcess` into `Nodulator.ExtendBeforeRun`
  - Added `Nodulator.ExtendAfterRun`
  - That fixes cachify_js bug if another render is processed

02/01/15: v0.0.5
  - Added index.jade file generation
  - Changed the way folders are configurated
  - Improved README
  - Files are automaticaly loaded by `!{nodulator()}` call
  - Added automatic compilation of views
