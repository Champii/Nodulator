N = require '..'

n = +process.env.MW || 1

Players = N.Resource 'player', N.Route.MultiRoute

for i til n
  Players.Create nb: i
    .fail -> console.error it
    .then ->
