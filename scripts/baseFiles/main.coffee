Nodulator = require 'Nodulator'
Server = require './server'

Nodulator.Config
  bootstrap: true

Server.Init()
Nodulator.Run()
