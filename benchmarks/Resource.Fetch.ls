N = require '..'
async = require 'async'

n = +process.env.MW || 1

Players = N.Resource 'player', N.Route.Collection


# async.eachSeries [til n]
# for i til n
#   Players.Create nb: i
#     .Catch console.error
#
# for i til n
#   Players.Fetch nb: i
#     .Catch console.error
