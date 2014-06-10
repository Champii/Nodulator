CoffeeHelper = require './lib/CoffeeHelper'

TestResource = CoffeeHelper.Resource 'test'

toAdd =
  test: 1

TestResource.Deserialize toAdd, (err, test) ->
  return console.log err if err?

  test.Save (err) ->
    return console.log err if err?

#   TestResource.Fetch 1, (err, test) ->
#     console.log err, test

