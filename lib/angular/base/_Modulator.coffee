class _Modulator

  directives: {}
  services: {}
  controllers: {}
  factories: {}

  Base: (name, injects...) ->
    Base name, injects

  Directive: (name, injects...) ->
    directive = Directive name, injects
    @directives[name] = directive if not @directives[name]?
    directive

  Service: (name, injects...) ->
    service = Service name, injects
    @services[name] = service if not @services[name]?
    service

  Factory: (name, injects...) ->
    factory = Factory name, injects
    @factories[name] = factory if not @factories[name]?
    factory

  ResourceService: (name, injects...) ->
    service = ResourceService name, injects
    @services[name] = service if not @services[name]?
    service

  Controller: (name, injects...) ->
    throw new Error 'Controller Not implemented'

Modulator = new _Modulator
