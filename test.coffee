CoffeeHelper = require './lib/CoffeeHelper'

ATest = CoffeeHelper.Resource 'test'
ATata = CoffeeHelper.Resource 'tata'

class TestResource extends ATest

  constructor: (blob) ->
    super blob

  LevelUp: (done) ->
    @level++
    @Save done

class TataResource extends ATata

  constructor: (blob) ->
    super blob

  LevelUp: (done) ->
    @level += 2
    @Save done

TestResource.Route 'put', '/:id/levelUp', (req, res) ->
  TestResource.Fetch req.params.id, (err, test) ->
    return res.send 500 if err?

    test.LevelUp (err) ->
      return res.send 500 if err?

      res.send 200, test.ToJSON()

TataResource.Route 'put', '/:id/levelUp', (req, res) ->
  TataResource.Fetch req.params.id, (err, tata) ->
    return res.send 500 if err?

    # console.log tata
    tata.LevelUp (err) ->
      return res.send 500 if err?

      res.send 200, tata.ToJSON()


toAdd =
  level: 1

TestResource.Deserialize toAdd, (err, test) ->
  return res.send 500 if err?

  test.Save (err) ->
    return res.send 500 if err?

toAdd =
  level: 1

TataResource.Deserialize toAdd, (err, tata) ->
  return res.send 500 if err?

  tata.Save (err) ->
    return res.send 500 if err?
