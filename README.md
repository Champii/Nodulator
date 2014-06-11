CoffeeHelper
============

Set of class for CoffeeScript to handle arbstract models

#Usage#

  Requirement:

    CoffeeHelper = require './lib/CoffeeHelper'

  Resource creation is easy.

    class PlayerResource extends CoffeeHelper.Resource 'player'

      LevelUp: (done) ->
        @level++

        @Save done

  It create automaticaly a table (in ram for the moment)

  It create also default routes

    GET   /api/1/player       => List
    GET   /api/1/player/:id   => Get One
    POST  /api/1/player       => Create
    PUT   /api/1/player/:id   => Update

  It create automaticaly 4 method

    Fetch(id, done)*
    List(done)*
    Deserialize(blob, done)*
    Save(done)
    Serialize()
    ToJSON()

    * Class methods


  You can define custom routes:

    PlayerResource.Route 'put', '/:id/levelUp', (req, res) ->
      PlayerResource.Fetch req.params.id, (err, player) ->
        return res.send 500 if err?

        test.LevelUp (err) ->
          return res.send 500 if err?

          res.send 200, player.ToJSON()



