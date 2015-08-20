_ = require 'underscore'
Nodulator = require '../'
request = require 'superagent'
async = require 'async'

weaponConfig =
  schema:
    hitPoints: 'int'

Weapons = Nodulator.Resource 'weapon', Nodulator.Route.MultiRoute, weaponConfig

unitConfig =
  abstract: true
  schema:
    level: 'int'
    life:  'int'
    weapon:
      type: Weapons
      localKey: 'weaponId'
      optional: true
    weaponId:
      type: 'int'
      optional: true

class Units extends Nodulator.Resource 'unit', unitConfig

  Attack: @_WrapPromise (target, done) ->
    target.life -= @weapon.hitPoints
    target.Save done

  LevelUp: @_WrapPromise (done) ->
    @level++
    @Save done

Units.Init()

class UnitRoute extends Nodulator.Route.MultiRoute
  Config: ->
    super()

    @Put '/:id/levelUp', (Req) ->
      Req.instance.LevelUp()

    @Put '/:id/attack/:targetId', (Req) =>
      # Hack to stay generic between children
      TargetResource = Monsters if @name is 'players'
      TargetResource = Players if @name is 'monsters'

      watcher = Nodulator.Watch ->
        Req.Send TargetResource.error() if TargetResource.error()?

      TargetResource.Fetch +Req.params.targetId (err, target) ->
        Req.instance.Attack target (err) ->
          Req.Send target
          watcher.Stop()

Players = Units.Extend 'player', UnitRoute
Monsters = Units.Extend 'monster', UnitRoute

/*
  Here stops the exemple,
  And Here start the tests.
*/

# Hack for keep track of weapon
weaponId = []

async.series
  addWeapon: (done) ->
    Nodulator.client.Post '/api/1/weapons', {hitPoints: 2}, (err, res) ->
      weaponId.push res.body.id
      done err, res.body

  addWeapon2: (done) ->
    Nodulator.client.Post '/api/1/weapons', {hitPoints: 1}, (err, res) ->
      weaponId.push res.body.id
      done err, res.body

  addPlayer: (done) ->
    Nodulator.client.Post '/api/1/players', {level: 1, life: 100, weaponId: weaponId[0]}, (err, res) -> done err, res.body

  testGet: (done) ->
    Nodulator.client.Get '/api/1/players', (err, res) -> done err, res.body

  levelUp: (done) ->
    Nodulator.client.Put '/api/1/players/1/levelUp', {}, (err, res) -> done err, res.body

  levelUp2: (done) ->
    Nodulator.client.Put '/api/1/players/1/levelUp', {}, (err, res) -> done err, res.body

  addMonster: (done) ->
    Nodulator.client.Post '/api/1/monsters', {level: 1, life: 20, weaponId: weaponId[1]}, (err, res) -> done err, res.body

  testGetMonster: (done) ->
    Nodulator.client.Get '/api/1/monsters', (err, res) -> done err, res.body

  levelUpMonster: (done) ->
    Nodulator.client.Put '/api/1/monsters/1/levelUp', {}, (err, res) -> done err, res.body

  levelUpMonster2: (done) ->
    Nodulator.client.Put '/api/1/monsters/1/levelUp', {}, (err, res) -> done err, res.body

  playerAttack: (done) ->
    Nodulator.client.Put '/api/1/players/1/attack/1', {}, (err, res) -> done err, res.body

  monsterAttack: (done) ->
    Nodulator.client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body

  monsterAttack1: (done) ->
    Nodulator.client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body

  monsterAttack2: (done) ->
    Nodulator.client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body

  monsterAttack3: (done) ->
    Nodulator.client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body

  monsterAttack4: (done) ->
    Nodulator.client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body

, (err, results) ->
  util = require 'util'
  util.debug util.inspect err, {depth: null}
  util.debug util.inspect results, {depth: null}
