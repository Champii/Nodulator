var coffeescript = require('coffee-script').register();
var livescript = require('livescript')
var Nodulator = require('./lib/Nodulator')

module.exports = Nodulator;
// var Tests = Nodulator.Resource('test', {schema: {test: 'int'}});
//
// Tests.Create({test:1}, function (err, test) {
//   console.log(err, test);
// });
