class _Modulator

  directives: {}

  Directive: (name, injects...) ->
    directive = Directive name, injects
    @directives[name] = directive
    directive

  Service: (name, injects) ->
    new Service name, injects

  Controller: (name, injects) ->
    new Controller name, injects

Modulator = new _Modulator
