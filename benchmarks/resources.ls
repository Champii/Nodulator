Nodulator = require '..'

n = +process.env.MW || 1
# console.log('  %s middleware', n);

Players = Nodulator.Resource 'player', Nodulator.Route.MultiRoute

for i til n
  Players.Create nb: i
  .fail -> console.error it
  .then ->

# Players.List!
# .fail -> console.error it
# .then -> console.log it
