class _N

  directives: {}
  services: {}
  controllers: {}
  factories: {}
  managedViews: {}
  nb: 0

  constructor: ->
    document.getElementsByTagName("body")[0].setAttribute("ng-app", "app")


  Base: (name, injects...) ->
    Base name, injects

  Directive: (name, injects...) ->
    directive = Directive name, injects
    if not @directives[name]?
      @directives[name] = directive
      @nb++
      if @nb is _nbDirectives
        @CreateEmptyTemplateDirective()

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
    controller = Controller name, injects
    @controllers[name] = controller if not @controllers[name]?
    controller

  CreateEmptyTemplateDirective: ->
    for template in _views when template not in _(@directives).keys()
      class _EmptyDirective extends @Directive template
      _EmptyDirective.Init()

N = new _N
