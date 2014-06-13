#
# Requirements
#

Modulator = require './lib/Modulator'

Modulator.Config
  dbType: 'SqlMem'
  dbAuth:
    host: 'localhost'
    user: 'test'
    pass: 'test'
    database: 'test'

#
# Resources declaration
#

APlayer = Modulator.Resource 'player'

AMonster = Modulator.Resource 'monster'

#
# Resources extension
#

class PlayerResource extends APlayer

  constructor: (blob) ->
    super blob

  LevelUp: (done) ->
    @level++
    @Save done

class MonsterResource extends AMonster

  constructor: (blob) ->
    super blob

  Attack: (target, done) ->
    target.life -= @hitPoint
    target.Save done

#
# Routes extension
#

PlayerResource.Route 'put', '/:id/levelUp', (req, res) ->
  PlayerResource.Fetch req.params.id, (err, player) ->
    return res.send 500 if err?

    player.LevelUp (err) ->
      return res.send 500 if err?

      res.send 200, player.ToJSON()

MonsterResource.Route 'put', '/:id/attack/:playerId', (req, res) ->
  MonsterResource.Fetch req.params.id, (err, monster) ->
    return res.send 500 if err?

    PlayerResource.Fetch req.params.playerId, (err, player) ->
      return res.send 500 if err?

      monster.Attack player, (err) ->
        return res.send 500 if err?

        res.send 200, player.ToJSON()

#
# Default values
#

toAdd =
  life: 10
  level: 1

PlayerResource.Deserialize toAdd, (err, player) ->
  return res.send 500 if err?

  player.Save (err) ->
    return res.send 500 if err?

toAdd =
  hitPoint: 1

MonsterResource.Deserialize toAdd, (err, monster) ->
  return res.send 500 if err?

  monster.Save (err) ->
    return res.send 500 if err?

