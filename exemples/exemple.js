var _ = require('underscore');
var Nodulator = require('../');
var request = require('superagent');
var async = require('async');

var weaponConfig = {
  schema: {
    hitPoints: 'int'
  }
};

var Weapons = Nodulator.Resource('weapon', Nodulator.Route.MultiRoute, weaponConfig);

var unitConfig = {
  abstract: true,
  schema: {
    level: 'int',
    life:  'int',
    weapon: {
      type: Weapons,
      localKey: 'weaponId',
      optional: true
    },
    weaponId: {
      type: 'int',
      optional: true
    }
  }
};

var Units = Nodulator.Resource('unit', unitConfig);

Units.prototype.Attack = Units._WrapPromise(function (target, done) {
  target.life -= this.weapon.hitPoints;
  target.Save(done);
});

Units.prototype.LevelUp = Units._WrapPromise(function (done) {
  this.level++;
  this.Save(done);
});

Units.Init();

var UnitRoute = Nodulator.Route.MultiRoute.Extend();

UnitRoute.prototype.Config = function () {
  Nodulator.Route.MultiRoute.prototype.Config.apply(this);

  this.Put('/:id/levelUp', function (Req) {
    Req.instance.LevelUp();
  });

  this.Put('/:id/attack/:targetId', function (Req) {
    // Hack to stay generic between children
    var TargetResource;
    if (this.name === 'players')
      TargetResource = Monsters;
    else if (this.name === 'monsters')
      TargetResource = Players;

    var watcher = Nodulator.Watch(function () {
      if (TargetResource.error() !== undefined)
        Req.Send(TargetResource.error());
    });

    TargetResource.Fetch(parseInt(Req.params.targetId), function (err, target) {
      Req.instance.Attack(target, function (err) {
        Req.Send(target);
        watcher.Stop();
      });
    });
  });
};

var Players = Units.Extend('player', UnitRoute);
var Monsters = Units.Extend('monster', UnitRoute);

//
//  Here stops the exemple,
//  And Here start the tests.
//
// Hack for keep track of weapon
weaponId = [];

async.series({
  addWeapon: function (done) {
    Nodulator.client.Post('/api/1/weapons', {hitPoints: 2}, function (err, res) {
      weaponId.push(res.body.id);
      done(err, res.body);
    });
  },

  addWeapon2: function (done) {
    Nodulator.client.Post('/api/1/weapons', {hitPoints: 1}, function (err, res) {
      weaponId.push(res.body.id);
      done(err, res.body);
    });
  },

  addPlayer: function (done) {
    Nodulator.client.Post('/api/1/players', {level: 1, life: 100, weaponId: weaponId[0]}, function (err, res) { done(err, res.body); });
  },

  testGet: function (done) {
    Nodulator.client.Get('/api/1/players', function (err, res) { done(err, res.body); });
  },

  levelUp: function (done) {
    Nodulator.client.Put('/api/1/players/1/levelUp', {}, function (err, res) { done(err, res.body); });
  },

  levelUp2: function (done) {
    Nodulator.client.Put('/api/1/players/1/levelUp', {}, function (err, res) { done(err, res.body); });
  },

  addMonster: function (done) {
    Nodulator.client.Post('/api/1/monsters', {level: 1, life: 20, weaponId: weaponId[1]}, function (err, res) { done(err, res.body); });
  },

  testGetMonster: function (done) {
    Nodulator.client.Get('/api/1/monsters', function (err, res) { done(err, res.body); });
  },

  levelUpMonster: function (done) {
    Nodulator.client.Put('/api/1/monsters/1/levelUp', {}, function (err, res) { done(err, res.body); });
  },

  levelUpMonster2: function (done) {
    Nodulator.client.Put('/api/1/monsters/1/levelUp', {}, function (err, res) { done(err, res.body); });
  },

  playerAttack: function (done) {
    Nodulator.client.Put('/api/1/players/1/attack/1', {}, function (err, res) { done(err, res.body); });
  },

  monsterAttack: function (done) {
    Nodulator.client.Put('/api/1/monsters/1/attack/1', {}, function (err, res) { done(err, res.body); });
  },

  monsterAttack1: function (done) {
    Nodulator.client.Put('/api/1/monsters/1/attack/1', {}, function (err, res) { done(err, res.body); });
  },

  monsterAttack2: function (done) {
    Nodulator.client.Put('/api/1/monsters/1/attack/1', {}, function (err, res) { done(err, res.body); });
  },

  monsterAttack3: function (done) {
    Nodulator.client.Put('/api/1/monsters/1/attack/1', {}, function (err, res) { done(err, res.body); });
  },

  monsterAttack4: function (done) {
    Nodulator.client.Put('/api/1/monsters/1/attack/1', {}, function (err, res) { done(err, res.body); });
  }
}, function (err, results) {
  util = require('util');
  util.debug(util.inspect(err, {depth: null}));
  util.debug(util.inspect(results, {depth: null}));
});
