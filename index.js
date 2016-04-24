// var coffeescript = require('coffee-script').register();
var livescript = require('livescript');
try {
  module.exports = require('./lib');
} catch (e) {
  module.exports = require('./src');
}

