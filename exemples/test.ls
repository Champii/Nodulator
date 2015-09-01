N = require '..'

Tests = N.Resource 'test'

log-fail = (.fail console.error; it)
log-then = (.then console.log; it)

log = log-fail >> log-then

watcher = N.Watch -> log Tests.Fetch 1

update-test = (val) -> (.test = val; it) >> (.Save!)

log-fail Tests.Create test: 1
  .then update-test 2
  .then update-test 1
  .then -> watcher.Stop!
  .then -> Tests.Fetch 1
  .then update-test 2
  .then update-test 1
