Modulator = require 'Modulator'
Server = require './server'

Modulator.Config
  bootstrap: true

Server.Init()
Modulator.Run()
