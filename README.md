CoffeeHelper
============

Set of class for CoffeeScript to handle arbstract models

#Usage#

  CoffeeHelper = require './lib/CoffeeHelper'

  class PlayerResource extends CoffeeHelper.Resource 'player'

    LevelUp: (done) ->
      @level++

      @Save done

  PlayerResource.Route 'put', '/:id/levelUp', (req, res) ->
    PlayerResource.Fetch req.params.id, (err, player) ->
      return res.send 500 if err?

      test.LevelUp (err) ->
        return res.send 500 if err?

        res.send 200, player.ToJSON()



