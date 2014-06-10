CoffeeHelper = require './lib/CoffeeHelper'

class TestResource extends CoffeeHelper.Resource

  constructor: (blob) ->
    super blob

TestResource.name = 'Test'

TestResource.Fetch 1, (err, test) ->
  console.log err, test
