N = require 'nodulator'

class ClientResource extends N.AccountResource 'client', N.Route.MultiRoute

ClientResource.Init()

module.exports = ClientResource
