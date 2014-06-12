CoffeeHelper
============

Set of class for CoffeeScript to handle arbstract models

#Usage#

  Requirement:

    CoffeeHelper = require './lib/CoffeeHelper'

  Resource declaration is easy.

    APlayer = CoffeeHelper.Resource 'player'

  Now you can create the resource itself

    class PlayerResource extends APlayer

      constructor: (blob) ->    # Optional
        super blob              #

      LevelUp: (done) ->
        @level++
        @Save done

  (Here we have a custom method: LevelUp)

  It create automaticaly a table (in ram for the moment)

  It create also default routes

    GET   /api/1/player       => List
    GET   /api/1/player/:id   => Get One
    POST  /api/1/player       => Create
    PUT   /api/1/player/:id   => Update

  It include 6 methods

    *Fetch(id, done)
    *List(done)
    *Deserialize(blob, done)
    Save(done)
    Serialize()
    ToJSON()

    * Class methods


  You can define custom routes:

    PlayerResource.Route 'put', '/:id/levelUp', (req, res) ->
      PlayerResource.Fetch req.params.id, (err, player) ->
        return res.send 500 if err?

        player.LevelUp (err) ->
          return res.send 500 if err?

          res.send 200, player.ToJSON()



