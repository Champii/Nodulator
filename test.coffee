CoffeeHelper = require './lib/CoffeeHelper'

class TestResource extends CoffeeHelper.Resource 'test'

  # constructor: (blob) ->

  LevelUp: (done) ->
    @level++

    @Save done

class TataResource extends CoffeeHelper.Resource 'tata'

  constructor: ->

TestResource.Route 'put', '/:id/levelUp', (req, res) ->
  TestResource.Fetch req.params.id, (err, test) ->
    return res.send 500 if err?

    # console.log test
    test.LevelUp (err) ->
      return res.send 500 if err?

      res.send 200, test.ToJSON()

# console.log TestResource

# TestResource = CoffeeHelper.Resource 'test'
# TataResource = CoffeeHelper.Resource 'tata'
# console.log TestResource


# TestResource.Method 'fetchWhere', false, (where, done) ->
#   @['table'].Select '*', where, {}, done

# TestResource.Method 'levelUp', true, (done) ->
#   @level++
#   console.log 'Save = ', @Save
#   @Save done

# console.log 'Res = ', TestResource


toAdd =
  level: 1

TestResource.Deserialize toAdd, (err, test) ->
  return res.send 500 if err?

  test.Save (err) ->
    return res.send 500 if err?

    # TestResource.List (err, result) ->
    #   return console.log err if err?

    #   console.log 'List: ', result

    # TestResource.fetchWhere {id: 1}, (err, list) ->
    #   return console.log err if err?

    #   test.levelUp (err) ->
    #     return console.log err if err?

    #     console.log test
