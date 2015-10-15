_ = require 'underscore'
N = require '../'
request = require 'superagent'
async = require 'async'

Weapons = N 'weapon', N.Route.MultiRoute

Weapons.Field \hitPoints \int


class Units extends N 'unit' abstract: true

  Attack: @_WrapPromise (targetId, done) ->
    @targetType.Fetch targetId
      .then ~>
        it.life -= @Weapon.hitPoints
        it.Save done
      .fail done

  LevelUp: @_WrapPromise (done) ->
    @level++
    @Save done

Units.Field \level \int
    ..Field \life \int
    ..HasOne Weapons

Units.Init()

class UnitRoute extends N.Route.MultiRoute

  Config: ->
    super()

    @Put '/:id/levelUp' -> it.instance.LevelUp!

    @Put '/:id/attack/:targetId' ~> it.instance.Attack +it.params.targetId

Players = Units.Extend 'player', UnitRoute
Monsters = Units.Extend 'monster', UnitRoute

/*
  Here stops the exemple,
  And Here start the tests.
*/

# Hack for keep track of weapon
weaponId = []

async.series do
  * addWeapon: (done) ->
      N.client.Post '/api/1/weapons', {hitPoints: 2}, (err, {body}) ->
        weaponId[*] = body.id
        done err, body

    addWeapon2: (done) ->
      N.client.Post '/api/1/weapons', {hitPoints: 1}, (err, {body}) ->
        weaponId[*] = body.id
        done err, body

    addPlayer: (done) ->
      N.client.Post '/api/1/players', {level: 1, life: 100, weaponId: weaponId.0}, (err, {body}) -> done err, body

    testGet: (done) ->
      N.client.Get '/api/1/players', (err, {body}) -> done err, body

    levelUp: (done) ->
      N.client.Put '/api/1/players/1/levelUp', {}, (err, {body}) -> done err, body

    levelUp2: (done) ->
      N.client.Put '/api/1/players/1/levelUp', {}, (err, {body}) -> done err, body

    testGetMonster: (done) ->
      N.client.Get '/api/1/monsters', (err, {body}) -> done err, body
    addMonster: (done) ->
      N.client.Post '/api/1/monsters', {level: 1, life: 20, weaponId: weaponId.1}, (err, {body}) -> done err, body

    testGetMonster2: (done) ->
      N.client.Get '/api/1/monsters', (err, {body}) -> done err, body

    levelUpMonster: (done) ->
      N.client.Put '/api/1/monsters/1/levelUp', {}, (err, {body}) -> done err, body

    levelUpMonster2: (done) ->
      N.client.Put '/api/1/monsters/1/levelUp', {}, (err, {body}) -> done err, body

    playerAttack: (done) ->
      N.client.Put '/api/1/players/1/attack/1', {}, (err, {body}) -> done err, body

    monsterAttack: (done) ->
      N.client.Put '/api/1/monsters/1/attack/1', {}, (err, {body}) -> done err, body

    monsterAttack1: (done) ->
      N.client.Put '/api/1/monsters/1/attack/1', {}, (err, {body}) -> done err, body

    monsterAttack2: (done) ->
      N.client.Put '/api/1/monsters/1/attack/1', {}, (err, {body}) -> done err, body

    monsterAttack3: (done) ->
      N.client.Put '/api/1/monsters/1/attack/1', {}, (err, {body}) -> done err, body

    monsterAttack4: (done) ->
      N.client.Put '/api/1/monsters/1/attack/1', {}, (err, {body}) -> done err, body

  , (err, results) ->
    util = require 'util'
    util.debug util.inspect err, {depth: null}
    util.debug util.inspect results, {depth: null}
