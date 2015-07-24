_ = require 'underscore'
Nodulator = require '../'
request = require 'superagent'
async = require 'async'

weaponConfig =
  schema:
    hitPoints: 'int'

Weapons = Nodulator.Resource 'weapon', Nodulator.Route.MultiRoute, weaponConfig

class UnitRoute extends Nodulator.Route.MultiRoute
  Config: ->
    super()

    @Put '/:id/levelUp', (req, res) ~>
      @instance.LevelUp (err) ~>
        return res.status(500).send err if err?

        res.status(200).send @instance.ToJSON()

    @Put '/:id/attack/:targetId', (req, res) ~>
      # Hack to stay generic between children
      TargetResource = Monsters if @name is 'players'
      TargetResource = Players if @name is 'monsters'

      TargetResource.Fetch req.params.targetId, (err, target) ~>
        return res.status(500) if err?

        @instance.Attack target, (err) ->
          return res.status(500) if err?

          res.status(200).send target.ToJSON()

unitConfig =
  abstract: true
  schema:
    level: 'int'
    life: 'int'
    weapon:
      type: Weapons
      localKey: 'weaponId'
      optional: true
    weaponId:
      type: 'int'
      optional: true

class Units extends Nodulator.Resource 'unit', unitConfig

  Attack: (target, done) ->
    target.life -= @weapon.hitPoints
    target.Save done

  LevelUp: (done) ->
    @level++
    @Save done

Units.Init()

Players = Units.Extend 'player', UnitRoute
Monsters = Units.Extend 'monster', UnitRoute



/*
  Here stops the exemple,
  And Here start the tests.
*/

Client = require '../test/common/client'
client = new Client Nodulator.app

# Hack for keep track of weapon
weaponId = []

async.series do
  * addWeapon: (done) ->
      client.Post '/api/1/weapons', {hitPoints: 2}, (err, res) ->
        weaponId.push res.body.id
        done err, res.body

    addWeapon2: (done) ->
      client.Post '/api/1/weapons', {hitPoints: 1}, (err, res) ->
        weaponId.push res.body.id
        done err, res.body

    addPlayer: (done) ->
      client.Post '/api/1/players', {level: 1, life: 100, weaponId: weaponId[0]}, (err, res) -> done err, res.body

    testGet: (done) ->
      client.Get '/api/1/players', (err, res) -> done err, res.body

    levelUp: (done) ->
      client.Put '/api/1/players/1/levelUp', {}, (err, res) -> done err, res.body

    levelUp2: (done) ->
      client.Put '/api/1/players/1/levelUp', {}, (err, res) -> done err, res.body

    addMonster: (done) ->
      client.Post '/api/1/monsters', {level: 1, life: 20, weaponId: weaponId[1]}, (err, res) -> done err, res.body

    testGetMonster: (done) ->
      client.Get '/api/1/monsters', (err, res) -> done err, res.body

    levelUpMonster: (done) ->
      client.Put '/api/1/monsters/1/levelUp', {}, (err, res) -> done err, res.body

    levelUpMonster2: (done) ->
      client.Put '/api/1/monsters/1/levelUp', {}, (err, res) -> done err, res.body

    playerAttack: (done) ->
      client.Put '/api/1/players/1/attack/1', {}, (err, res) -> done err, res.body

    monsterAttack: (done) ->
      client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body

    monsterAttack1: (done) ->
      client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body

    monsterAttack2: (done) ->
      client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body

    monsterAttack3: (done) ->
      client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body

    monsterAttack4: (done) ->
      client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body

  , (err, results) ->
    util = require 'util'
    util.debug util.inspect err, {depth: null}
    util.debug util.inspect results, {depth: null}
