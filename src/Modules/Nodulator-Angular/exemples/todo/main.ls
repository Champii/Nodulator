Nodulator = require 'nodulator'
Socket = require 'nodulator-socket'
Assets = require 'nodulator-assets'
Angular = require 'nodulator-angular'
Server = require './server'

Nodulator.Use Socket
Nodulator.Use Assets
Nodulator.Use Angular

Server.Init()
Nodulator.Run()
