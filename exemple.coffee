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

AWeapon = Modulator.Resource 'weapon'

AMonster = Modulator.Resource 'monster'

#
# Resources extension
#

class PlayerResource extends APlayer

  constructor: (blob, @weapon) ->
    super blob

  LevelUp: (done) ->
    @level++
    @Save done

  Attack: (target, done) ->
    target.life -= @weapon.hitPoint
    target.Save done

  @Deserialize: (blob, done) ->
    WeaponResource.Fetch blob.weapon_id, (err, weapon) ->
      return done err if err?

      done null, new PlayerResource blob, weapon

class WeaponResource extends AWeapon

class MonsterResource extends AMonster

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

PlayerResource.Route 'put', '/:id/attack/:monsterId', (req, res) ->
  PlayerResource.Fetch req.params.id, (err, player) ->
    return res.send 500 if err?

    MonsterResource.Fetch req.params.monsterId, (err, monster) ->
      return res.send 500 if err?

      player.Attack monster, (err) ->
        return res.send 500 if err?

        res.send 200, monster.ToJSON()

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
  hitPoint: 2

WeaponResource.Deserialize toAdd, (err, weapon) ->
  return res.send 500 if err?

  weapon.Save (err) ->
    return res.send 500 if err?

    toAdd =
      life: 10
      level: 1
      weapon_id: weapon.id

    PlayerResource.Deserialize toAdd, (err, player) ->
      return res.send 500 if err?

      player.Save (err) ->
        return res.send 500 if err?

toAdd =
  life: 10
  hitPoint: 1

MonsterResource.Deserialize toAdd, (err, monster) ->
  return res.send 500 if err?

  monster.Save (err) ->
    return res.send 500 if err?

