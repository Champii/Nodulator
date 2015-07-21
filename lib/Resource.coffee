_ = require 'underscore'
async = require 'async'
Nodulator = require '../'
Validator = require 'validator'
Hacktiv = require 'hacktiv'
ChangeWatcher = require './ChangeWatcher'
Wrappers = require './Wrappers'

validationError = (field, value, message) ->
  field: field
  value: value
  message: "The '#{field}' field with value '#{value}' #{message}"

typeCheck =
  bool: (value) -> typeof(value) isnt 'string' and '' + value is 'true' or '' + value is 'false'
  int: Validator.isInt
  string: (value) -> true # FIXME: call add subCheckers
  date: Validator.isDate
  email: Validator.isEmail
  array: (value) -> Array.isArray value
  arrayOf: (type) -> (value) => !_(@[type] v for v in value).contains (item) -> item is false

Nodulator.Validator = Validator

module.exports = (table, config, app, routes, name) ->

  error = new Hacktiv.Value

  class Resource extends Wrappers

    @DEFAULT_DEPTH: 1
    @INITED: false
    @error: error

    constructor: (blob) ->
      @_table = @.__proto__.constructor._table
      @_schema = @.__proto__.constructor._schema
      @_type = @.__proto__.constructor.lname

      @id = blob?.id || null

      if @_schema?
        for field, description of @_schema when blob[field]?
          @[field] = blob[field]

        for assoc in @_schema._assoc
          @[assoc.name] = blob[assoc.name]

        for field, description of @_schema when not blob[field]? and description.default?
          @[field] = description.default

        @id = blob.id
      else
        for field, value of blob
          @[field] = blob[field]

    Save: @_WrapFlipDone @_WrapPromise (args...) -> @_SaveUnwrapped args...

    _SaveUnwrapped: (done) ->
      Resource._Validate @Serialize(), true, (err) =>
        return done err if err?

        exists = @id?

        @_table.Save @Serialize(), (err, id) =>
          return done err if err?

          if !exists
            @id = id
            Nodulator.bus.emit 'new_' + name, @ToJSON()
          else
            Nodulator.bus.emit 'update_' + name, @ToJSON()

          ChangeWatcher.Invalidate()

          done null, @

      @

    Delete: @_WrapFlipDone @_WrapPromise (args...) -> @_DeleteUnwrapped args...

    _DeleteUnwrapped: (done) ->
      @_table.Delete @id, (err) =>
        return done err if err?

        Nodulator.bus.emit 'delete_' + name, @ToJSON()
        ChangeWatcher.Invalidate()
        done()

      null

    # Get what to send to the database
    Serialize: ->
      res = if @id? then id: @id else {}
      if @_schema?
        for field, description of @_schema when field isnt '_assoc'
          res[field] = @[field]

      else
        for field, description of @ when field[0] isnt '_'
          res[field] = @[field]

      res

    # Get what to send to client
    ToJSON: ->
      res = @Serialize()
      if @_schema?
        for assoc in @_schema._assoc
          if @[assoc.name]? and Array.isArray @[assoc.name]
            res[assoc.name] = _(@[assoc.name]).invoke 'ToJSON'
          else if @[assoc.name]?
            res[assoc.name] = @[assoc.name].ToJSON()
      res

    ExtendSafe: (blob) ->
      return _(@).extend blob if not @_schema?

      newBlob = _({}).extend blob

      for assoc in @_schema._assoc
        delete newBlob[assoc.name]

      _(@).extend newBlob

    @_Validate: (blob, full, done) ->
      return done() if not config? or not config.schema?

      if not done?
        done = full
        full = false

      errors = []

      for field, validator of @_schema when validator? and field isnt '_assoc'

        if full and not blob[field]? and not config?.schema?[field]?.optional and
           not config?.schema?[field]?.default
          errors.push validationError field, blob[field], ' was not present.'

        else if blob[field]? and not validator(blob[field])
          errors.push validationError field,
                                      blob[field],
                                      ' was not a valid ' + config.schema[field].type

        for field, value of blob when not @_schema[field]? and
                                      field isnt 'id' and
                                      field not in _(@_schema._assoc).pluck 'name'

          errors.push validationError field, blob[field], ' is not in schema'

      done(if errors.length then {errors} else null)

    # Wrapper to allow simple variable or array as first argument
    @_HandleArrayArg: (arg, callback, done) ->
      if Array.isArray arg
        async.map arg, callback, done
      else
        callback arg, done

      # Returs this to avoid writing it in every call
      @

    # _Deserialize and Save from a blob or an array of blob
    @Create: @_WrapFlipDone @_WrapPromise (args, done, _depth = @config?.maxDepth || @DEFAULT_DEPTH) =>
      @Init() if not @INITED

      @_HandleArrayArg args, (blob, done) =>
        @resource._Deserialize blob, (err, instance) ->
          return done err if err?

          instance._SaveUnwrapped done
        , _depth
      , done

    # Fetch from id or id array
    @Fetch: @_WrapFlipDone @_WrapPromise @_WrapWatchArgs (arg, done, _depth = @config?.maxDepth || @DEFAULT_DEPTH) =>
      @Init() if not @INITED

      cb = (done) =>
        (err, blob) =>
          return done err if err?

          @resource._Deserialize blob, done, _depth

      @_HandleArrayArg arg, (constraints, done) =>
        if typeof(constraints) is 'object'
          @_table.FindWhere '*', constraints, cb done
        else
          @_table.Find constraints, cb done
      , done

    # Get every records from db
    @List: @_WrapFlipDone @_WrapPromise @_WrapWatchArgs (arg, done, _depth = @config?.maxDepth || @DEFAULT_DEPTH) =>
      @Init() if not @INITED

      if typeof(arg) is 'function'
        if typeof(done) is 'number'
          _depth = done

        done = arg
        arg = {}


      @_HandleArrayArg arg, (constraints, done) =>
        @_table.Select '*', (constraints || {}), {}, (err, blobs) =>
          return done err if err?

          async.map blobs, (blob, done) =>
            @resource._Deserialize blob, done, _depth
          , done
      , done

    @Delete: @_WrapFlipDone @_WrapPromise (arg, done) =>
      @Init() if not @INITED

      @_HandleArrayArg arg, (constraints, done) =>
        @resource.Fetch constraints, (err, instance) =>
          return done err if err?

          instance._DeleteUnwrapped done
      , done

    # Pre-Instanciation and associated model retrival
    @_Deserialize: (blob, done, _depth = @config?.maxDepth || @DEFAULT_DEPTH) ->
      @Init() if not @INITED

      @_Validate blob, true, (err) =>
        return done err if err?

        res = @
        if @_schema?
          @_FetchAssoc blob, (err, blob) ->
            return done err if err?

            done null, new res blob
          , _depth
        else
          done null, new res blob

    @_FetchAssoc: (blob, done, _depth) ->
      assocs = {}

      async.each @_schema._assoc, (resource, done) =>
        resource.Get blob, (err, instance) =>
          assocs[resource.name] = resource.default if resource.default?
          return done err if err? and config?.schema?
          return done() if err? and config? and config.schema?[resource.name]?.optional

          assocs[resource.name] = instance
          done()
        , _depth
      , (err) ->
        return done err if err?

        done null, _.extend blob, assocs

    @_PrepareResource: (_table, _config, _app, _routes, _name) ->
      @_table = _table
      @config = _config
      @app = _app
      @lname = _name.toLowerCase()
      @resource = @
      if _routes?
        @routes = new _routes(@, @config)

      @

    @_PrepareRelationship: (isArray, field, description) ->
      get = (blob, done) ->
        done new Error 'No local or distant key given'

      if description.localKey?
        get = (blob, done, _depth) ->
          if not _depth
            return done()

          if !isArray
            if not typeCheck.int blob[description.localKey]
              return done new Error 'Model association needs integer as id and key'
          else
            if not typeCheck.array blob[description.localKey]
              return done new Error 'Model association needs array of integer as ids and localKeys'

          description.type.Fetch blob[description.localKey], done, _depth - 1

      else if description.distantKey?
        get = (blob, done, _depth) ->
          if not _depth
            return done()

          if !isArray
            description.type.FetchBy blob[description.distantKey], done, _depth - 1
          else
            constaints = {}
            constaints[description.distantKey] = blob.id
            description.type.ListBy constaints, done, _depth - 1

      toPush  =
        name: field
        Get: get
      toPush.default = description.default if description.default?
      @_schema._assoc.push toPush

    @_PrepareSchema: ->
      @_schema = {_assoc: []}

      for field, description of @config.schema

        isArray = false
        if description.type? and Array.isArray description.type
          isArray = true
          description.type = description.type[0]
        else if Array.isArray description
          isArray = true
          description = description[0]

        if description.type? and typeof description.type is 'function'
          @_PrepareRelationship isArray, field, description

        else if description.type?
          if description.default?
            if typeof(description.default) is 'function'
              @::[field] = description.default()
            else
              @::[field] = description.default
          @_schema[field] = typeCheck[description.type]
          if isArray
            @_schema[field] = typeCheck.arrayOf description.type

        else if typeof(description) is 'string'
          if isArray
            @_schema[field] = typeCheck.arrayOf description
          else
            @_schema[field] = typeCheck[description]

    @_PrepareAbstract: ->
      @Extend = (name, routes, config) =>
        @Init() it not @INITED
        if config and not config.abstract
          deleteAbstract = true

        config = _(config).extend @config

        if deleteAbstract
          delete config.abstract

        Nodulator.Resource name, routes, config, @

    @Init: (@config = @config) ->
      @resource = @
      Nodulator.resources[@lname] = @

      if @config? and @config.schema
        @_PrepareSchema()

      #if @config? and @config.abstract
      @_PrepareAbstract()

      @INITED = true

      @


  Resource._PrepareResource(table, config, app, routes, name)
