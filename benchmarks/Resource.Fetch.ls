Nodulator = require '..'

n = +process.env.MW || 1

Players = Nodulator.Resource 'player', Nodulator.Route.MultiRoute

for i til n
  Players.Create nb: i
    .fail -> console.error it
    .then ->

for i til n
  Players.Fetch nb: i
    .fail -> console.error it
    .then ->
