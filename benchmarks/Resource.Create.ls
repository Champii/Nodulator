N = require '..'

# n = +process.env.MW || 1

N.Config do
  cache:
    type: \Redis
#
Players = N \player N.Route.MultiRoute .Init!

# for i til n
#   Players.Create!
#     .Catch console.error
# Players.Watch \new console.log
