try {
  module.exports = require('./lib');
} catch (e) {
  var livescript = require('livescript');
  module.exports = require('./src');
}
