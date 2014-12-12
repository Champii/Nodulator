class _Modulator

  directives: {}
  services: {}
  controllers: {}

  Directive: (name, injects...) ->
    directive = Directive name, injects
    @directives[name] = directive
    directive

  Service: (name, injects...) ->
    service = Service name, injects
    @services[name] = service
    service

  Controller: (name, injects) ->
    new Controller name, injects

Modulator = new _Modulator
