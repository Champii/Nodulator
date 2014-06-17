#
# Requirements
#

Modulator = require './lib/Modulator'

Modulator.Config
  dbType: 'Mongo'         # You can select 'SqlMem' to use inRAM Document (no persistant data, used to test) or 'Mongo' or 'Mysql'
  dbAuth:
    host: 'localhost'
    database: 'test'
    port: 27017           # Working only for Mongo (can be ignored, default value is 27017)
    # user: 'test'        # For Mongo and SqlMem, these fields are optionals
    # pass: 'test'        #

#
# Resources declaration
#

APlayer = Modulator.Resource 'player',
  account:
    fields:
      usernameField: "login"
      passwordField: "pass"

AWeapon = Modulator.Resource 'weapon'

AMonster = Modulator.Resource 'monster'


#
# Resources extension
#

class PlayerResource extends APlayer

  # We override the constructor to attach a weapon
  constructor: (blob, @weapon) ->
    # Never forget to call the super with blob attached
    # If you do, you'll have to define yourself properties that are attached to blob
    super blob

  # New instance method
  # Fields are dynamics. They depend on what you saved
  LevelUp: (done) ->
    @level++
    @Save done

  # New instance method to attack a target
  # Here we take the weapon attached to get hitPoints
  Attack: (target, done) ->
    target.life -= @weapon.hitPoint
    target.Save done

  # Overriding of APlayer's @Deserialize class method to fetch and attach Weapon
  @Deserialize: (blob, done) ->
    if !(blob.id?)
      return super blob, done

    WeaponResource.FetchByUserId blob.id, (err, weapon) ->
      return done err if err?

      done null, new PlayerResource blob, weapon

class WeaponResource extends AWeapon

  # We add a new class method to fetch weapon by userId
  # Added for usecase exemple of @table
  @FetchByUserId: (userId, done) ->
    @table.FindWhere '*', {userId: userId}, (err, blob) =>
      return done err if err?

      @Deserialize blob, done

class MonsterResource extends AMonster

  # Here we only define a new Attack instance method
  Attack: (target, done) ->
    target.life -= @hitPoint
    target.Save done

#
# Routes extension
#

# Player LevelUp
PlayerResource.Route 'put', '/:id/levelUp', (req, res) ->
  return res.send 403 if !(req.user?)

  PlayerResource.Fetch req.params.id, (err, player) ->
    return res.send 500 if err?
    return res.send 403 if req.user.login isnt player.login

    player.LevelUp (err) ->
      return res.send 500 if err?

      res.send 200, player.ToJSON()

# Player Attack
PlayerResource.Route 'put', '/:id/attack/:monsterId', (req, res) ->
  return res.send 403 if !(req.user?)

  PlayerResource.Fetch req.params.id, (err, player) ->
    return res.send 500 if err?
    return res.send 403 if req.user.login isnt player.login

    MonsterResource.Fetch req.params.monsterId, (err, monster) ->
      return res.send 500 if err?

      player.Attack monster, (err) ->
        return res.send 500 if err?

        res.send 200, monster.ToJSON()

# Monster Attack
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
  login: "lol"
  pass: "lol"
  life: 10
  level: 1

PlayerResource.Deserialize toAdd, (err, player) ->
  return console.error err if err?

  player.Save (err) ->
    return console.error err if err?

    toAdd =
      userId: player.id
      hitPoint: 2

    WeaponResource.Deserialize toAdd, (err, weapon) ->
      return console.error err if err?

      weapon.Save (err) ->
        return console.error err if err?


toAdd =
  life: 10
  hitPoint: 1

MonsterResource.Deserialize toAdd, (err, monster) ->
  return console.error err if err?

  monster.Save (err) ->
    return console.error err if err?

