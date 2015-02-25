_ = require 'underscore'
Nodulator = require './'
request = require 'superagent'
async = require 'async'

weaponConfig =
  schema:
    hitPoints:
      type: 'int'

class WeaponResource extends Nodulator.Resource 'weapon', Nodulator.Route.DefaultRoute, weaponConfig

WeaponResource.Init()

unitConfig =
  abstract: true
  schema:
    level:
      type: 'int'
    life:
      type: 'int'
    weapon:
      type: WeaponResource
      localKey: 'weaponId'
      optional: true
    weaponId:
      type: 'int'
      optional: true

class UnitRoute extends Nodulator.Route.DefaultRoute
  Config: ->
    super()

    @Put '/:id/levelUp', (req, res) =>
      req.resources[@resource.lname].LevelUp (err) =>
        return res.status(500).send err if err?

        res.status(200).send req.resources[@resource.lname].ToJSON()

    @Put '/:id/attack/:targetId', (req, res) =>
      # Hack to stay generic between children
      TargetResource = MonsterResource if @name is 'players'
      TargetResource = PlayerResource if @name is 'monsters'

      TargetResource.Fetch req.params.targetId, (err, target) =>
        return res.status(500) if err?

        req.resources[@resource.lname].Attack target, (err) ->
          return res.status(500) if err?

          res.status(200).send target.ToJSON()

class UnitResource extends Nodulator.Resource 'unit', unitConfig
  Attack: (target, done) ->
    target.life -= @weapon.hitPoints
    target.Save done

  LevelUp: (done) ->
    @level++
    @Save done

UnitResource.Init()

class PlayerResource extends UnitResource.Extend 'player', UnitRoute

PlayerResource.Init()

class MonsterResource extends UnitResource.Extend 'monster', UnitRoute

MonsterResource.Init()

Client = require './test/common/client'
client = new Client Nodulator.app

# Hack for keep track of weapon
weaponId = 0

async.series
  addWeapon: (done) ->
    client.Post '/api/1/weapons', {hitPoints: 1}, (err, res) ->
      weaponId = res.body.id
      done err, res.body

  addPlayer: (done) ->
    client.Post '/api/1/players', {level: 1, life: 20, weaponId: weaponId}, (err, res) -> done err, res.body

  testGet: (done) ->
    client.Get '/api/1/players', (err, res) -> done err, res.body

  levelUp: (done) ->
    client.Put '/api/1/players/1/levelUp', {}, (err, res) -> done err, res.body

  levelUp2: (done) ->
    client.Put '/api/1/players/1/levelUp', {}, (err, res) -> done err, res.body

  addMonster: (done) ->
    client.Post '/api/1/monsters', {level: 1, life: 20, weaponId: weaponId}, (err, res) -> done err, res.body

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
