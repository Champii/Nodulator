var N = require('..')

var WeaponRoute = N.Route.Extend();

WeaponRoute.prototype.Config = function () {
  var thus = this;
  this.Get(function () {
    return thus.resource.List();
  });
};

var Weapon = N('weapon', WeaponRoute, {schema: 'strict'});
Weapon.Field('power', 'int').Default(10);

var Unit = N('unit', {abstract: true, schema: 'strict'});

Unit.prototype.LevelUp = function () {
  return this.Set({level: this.level + 1});
};

Unit.prototype.Attack = function (targetId) {
  var thus = this;
  if (!this.Weapon)
    throw('No weapon');

  var Target;
  if (this._type === 'player')
    Target = Monster;
  else if (this._type === 'monster')
    Target = Player;

  return Target.Fetch(targetId).Set(function (target) {target.life -= thus.Weapon.power});
};

Unit.Field('level', 'int') .Default(1);
Unit.Field('life', 'int')  .Default(100);
Unit.MayBelongsTo(Weapon)

var UnitRoute = N.Route.MultiRoute.Extend();

UnitRoute.prototype.Config = function () {
  N.Route.MultiRoute.prototype.Config.apply(this, arguments);

  this.Put('/:id/levelup', function (req) {
    return req.instance.LevelUp();
  });

  this.Put('/:id/attack/:targetId', function (req) {
    return req.instance.Attack(parseInt(req.params.targetId));
  });
};

var Player =  Unit.Extend('player',  UnitRoute);
var Monster = Unit.Extend('monster', UnitRoute);

// Exemple seed:
Player.Create().Add(Weapon.Create({power: 25}));
Monster.Create().Add(Weapon.Create());

// Created routes :
//  - GET    /api/1/players                       => Get all players
//  - GET    /api/1/players/:id                   => Get player with given id
//  - POST   /api/1/players                       => Create a player
//  - PUT    /api/1/players/:id                   => Modify the player with given id
//  - DELETE /api/1/players/:id                   => Delete the given player
//  - PUT    /api/1/players/:id/levelup           => LevelUp the given player
//  - PUT    /api/1/players/:id/attack/:targetId  => Attack the given monster
//
//  - GET    /api/1/monsters                      => Get all monsters
//  - GET    /api/1/monsters/:id                  => Get monster with given id
//  - POST   /api/1/monsters                      => Create a monster
//  - PUT    /api/1/monsters/:id                  => Modify the monster with given id
//  - DELETE /api/1/monsters/:id                  => Delete the given monster
//  - PUT    /api/1/monsters/:id/levelup          => LevelUp the given monster
//  - PUT    /api/1/monsters/:id/attack/:targetId => Attack the given player
//
//  - GET    /api/1/weapons                       => Get all weapons
