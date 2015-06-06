_ = require 'underscore'
async = require 'async'

Nodulator = require '../'
Validator = require 'validator'

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

  class Resource

    @DEFAULT_DEPTH: 1

    constructor: (blob) ->
      @_table = @.__proto__.constructor._table
      @_schema = @.__proto__.constructor._schema
      @_type = @.__proto__.constructor.lname

      @id = blob.id || null

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

    Save: (done) ->
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

          done null, @

    Delete: (done) ->
      @_table.Delete @id, (err) =>
        return done err if err?

        Nodulator.bus.emit 'delete_' + name, @ToJSON()
        done()

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
    @_MultiArgsWrap: (arg, callback, done) ->
      if Array.isArray arg
        async.map arg, callback, done
      else
        callback arg, done

    # Fetch from id or id array
    @Fetch: (arg, done, _depth = @config?.maxDepth || @DEFAULT_DEPTH) ->
      @_MultiArgsWrap arg, (id, done) =>
        @_table.Find id, (err, blob) =>
          return done err if err?

          # console.log 'fetch blob', blob
          @resource.Deserialize blob, done, _depth
      , done

    # Get every records satisfying given constraints
    @FetchBy: (constraints, done, _depth = @config?.maxDepth || @DEFAULT_DEPTH) ->
      @_table.FindWhere '*', constraints, (err, blob) =>
        return done err if err?

        @resource.Deserialize blob, done, _depth

    # Get every records from db
    @List: (done, _depth = @config?.maxDepth || @DEFAULT_DEPTH) ->
      @_table.Select 'id', {}, {}, (err, ids) =>
        return done err if err?

        @resource.Fetch _(ids).pluck('id'), done, _depth

    # Get every records satisfying given constraints
    @ListBy: (constraints, done, _depth = @config?.maxDepth || @DEFAULT_DEPTH) ->
      @_table.Select 'id', constraints, {}, (err, ids) =>
        return done err if err?

        @resource.Fetch _(ids).pluck('id'), done, _depth

    # Deserialize and Save from a blob or an array of blob
    @Create: (args, done, _depth = @config?.maxDepth || @DEFAULT_DEPTH) ->
      @_MultiArgsWrap args, (blob, done) =>
        @Deserialize blob, (err, resource) ->
          return done err if err?

          resource.Save done
        , _depth
      , done

    # Pre-Instanciation and associated model retrival
    @Deserialize: (blob, done, _depth) ->
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
      @_routes = _routes

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

      if @config? and @config.abstract
        @_PrepareAbstract()

      else if @_routes?
        @routes = new @_routes(@, @app, @config)

      @

  Resource._PrepareResource(table, config, app, routes, name)
