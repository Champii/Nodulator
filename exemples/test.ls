N = require '..'

Tests = N.Resource 'test'

log-fail = (.fail console.error; it)
log-then = (.then console.log; it)

log = log-fail >> log-then

watcher = N.Watch -> (log-then >> (.then (.ToJSON!))) Tests.List test: 1

update-test = (val) -> (.test = val; it) >> (.Save!)

log-fail Tests.Create test: 1     # id == 1
  .then update-test 4
  .then update-test 5
  .then update-test 1
  .then -> Tests.Create test: 1   # id == 2
  .then -> Tests.Create test: 1   # id == 3
  .then -> watcher.Stop!
  .then -> Tests.Fetch 1
  .then update-test 1
  .then console.log
