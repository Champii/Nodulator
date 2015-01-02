Nodulator = require './'
request = require 'superagent'
async = require 'async'

class WeaponRoute extends Nodulator.Route.DefaultRoute

class WeaponResource extends Nodulator.Resource('weapon', WeaponRoute)
  @FetchByUserId: (userId, done) ->
    @table.FindWhere '*', {userId: userId}, (err, blob) =>
      return done err if err?

      @Deserialize blob, done

  @FetchByMonsterId: (monsterId, done) ->
    @table.FindWhere '*', {monsterId: monsterId}, (err, blob) =>
      return done err if err?

      @Deserialize blob, done

WeaponResource.Init()

class UnitRoute extends Nodulator.Route.DefaultRoute
  Config: ->
    super()

    @Put '/:id/levelUp', (req, res) =>
      req[@resource.lname].LevelUp (err) =>
        return res.status(500).send err if err?

        res.status(200).send req[@resource.lname].ToJSON()

    @Put '/:id/attack/:targetId', (req, res) =>
      TargetResource = MonsterResource if @name is 'players'
      TargetResource = PlayerResource if @name is 'monsters'

      TargetResource.Fetch req.params.targetId, (err, target) =>
        return res.status(500) if err?

        req[@resource.lname].Attack target, (err) ->
          return res.status(500) if err?

          res.status(200).send target.ToJSON()

class UnitResource extends Nodulator.Resource('unit', {abstract: true})
  constructor: (blob, @weapon) ->
    super blob

  Attack: (target, done) ->
    target.life -= @weapon.hitpoints if @weapon?
    target.Save done

  LevelUp: (done) ->
    @level++
    @Save done

UnitResource.Init()

class PlayerRoute extends UnitRoute

class PlayerResource extends UnitResource.Extend('player', PlayerRoute)
  @Deserialize: (blob, done) ->
    if !(blob.id?)
      return super blob, done

    WeaponResource.FetchByUserId blob.id, (err, weapon) =>
      res = @
      done null, new res blob, weapon

PlayerResource.Init()

class MonsterRoute extends UnitRoute

class MonsterResource extends UnitResource.Extend('monster', MonsterRoute)
  @Deserialize: (blob, done) ->
    if !(blob.id?)
      return super blob, done

    WeaponResource.FetchByMonsterId blob.id, (err, weapon) =>
      res = @
      done null, new res blob, weapon

MonsterResource.Init()

Client = require './test/common/client'
client = new Client Nodulator.app

async.series
  addPlayer: (done) ->
    client.Post '/api/1/players', {level: 1, life: 10}, (err, res) -> done err, res.body

  testGet: (done) ->
    client.Get '/api/1/players', (err, res) -> done err, res.body

  levelUp: (done) ->
    client.Put '/api/1/players/1/levelUp', {}, (err, res) -> done err, res.body

  levelUp2: (done) ->
    client.Put '/api/1/players/1/levelUp', {}, (err, res) -> done err, res.body

  addMonster: (done) ->
    client.Post '/api/1/monsters', {level: 1, life: 20}, (err, res) -> done err, res.body

  testGetMonster: (done) ->
    client.Get '/api/1/monsters', (err, res) -> done err, res.body

  levelUpMonster: (done) ->
    client.Put '/api/1/monsters/1/levelUp', {}, (err, res) -> done err, res.body

  levelUpMonster2: (done) ->
    client.Put '/api/1/monsters/1/levelUp', {}, (err, res) -> done err, res.body

  addPlayerWeapon: (done) ->
    client.Post '/api/1/weapons', {hitpoints: 1, userId: 1}, (err, res) -> done err, res.body

  addMonsterWeapon: (done) ->
    client.Post '/api/1/weapons', {hitpoints: 3, monsterId: 1}, (err, res) -> done err, res.body

  playerAttack: (done) ->
    client.Put '/api/1/players/1/attack/1', {}, (err, res) -> done err, res.body

  monsterAttack: (done) ->
    client.Put '/api/1/monsters/1/attack/1', {}, (err, res) -> done err, res.body


, (err, results) ->
  console.log err, results
