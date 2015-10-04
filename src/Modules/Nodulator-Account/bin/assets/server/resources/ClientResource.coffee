Nodulator = require 'nodulator'

class ClientResource extends Nodulator.AccountResource 'client', Nodulator.Route.MultiRoute

ClientResource.Init()

module.exports = ClientResource
