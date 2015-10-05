N = require 'nodulator'
Socket = require 'nodulator-socket'
Assets = require 'nodulator-assets'
Angular = require 'nodulator-angular'
Server = require './server'

N.Use Socket
N.Use Assets
N.Use Angular

Server.Init()
N.Run()
