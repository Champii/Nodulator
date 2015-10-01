require! {
  \.. : N
  \prelude-ls : {is-type, map, last}
  \async-ls
  fs
}

global import async-ls.callbacks

Tests = N.Resource 'test'

cb = (err, res) ->
  return console.error err if err?

  console.log res

create = (val, done) -->
  Tests.Create val, done

f1 = sequenceA do
  * create toto: \toto
  * create toto: \tata
  * create toto: \tutu

f1 cb
# f2 cb


# cb1 = (err, res) ->
#   console.log err, res
#
# f1 = returnA 10
#
# f2 = fmapA (+ 2), f1
#
# f2 cb1

# Tests = N.Resource 'test'
#
# log-fail = (.fail console.error; it)
# log-then = (.then console.log; it)
#
# log-q = log-fail >> log-then
#
# log-q-json = (.then (.ToJSON!) |> log-q)
#
# watcher = N.Watch -> log-q-json Tests.Fetch 1
#
# update-test = (val) -> (.test = val; it) >> (.Save!)
#
# log-fail Tests.Create test: 1
#   .then update-test 2
#   .then update-test 1
#   .then -> watcher.Stop!
#   .then -> Tests.Fetch 1
#   .then update-test 2
#   .then update-test 1
#   |> log-q-json
