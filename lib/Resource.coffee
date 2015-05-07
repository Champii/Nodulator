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
  arrayOf: (type) -> (value) => @[type] v for v in value

Nodulator.Validator = Validator

module.exports = (table, config, app, routes, name) ->

  class Resource

    constructor: (blob) ->
      @_table = @.__proto__.constructor._table
      @_schema = @.__proto__.constructor._schema

      @id = blob.id || null

      if @_schema?
        for field, description of @_schema when blob[field]?
          @[field] = blob[field]

        for assoc in @_schema._assoc
          @[assoc.name] = blob[assoc.name]

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
            Nodulator.bus.emit 'new_' + name, @Serialize()
          else
            Nodulator.bus.emit 'update_' + name, @Serialize()

          done null, @

    Delete: (done) ->
      @_table.Delete @id, (err) =>
        return done err if err?

        Nodulator.bus.emit 'delete_' + name, @Serialize()
        done()

    # Get what to send to the database
    Serialize: ->
      res = if @id? then {id: @id} else {}
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
          if Array.isArray @[assoc.name]
            res[assoc.name] = _(@[assoc.name]).invoke 'Serialize'
          else
            res[assoc.name] = @[assoc.name].Serialize()
      res

    @_Validate: (blob, full, done) ->
      return done() if not config? or not config.schema?

      if not done?
        done = full
        full = false

      errors = []

      for field, validator of @_schema when validator? and field isnt '_assoc'

        if full and not blob[field]? and not config?.schema?[field]?.optional and not config?.schema?[field]?.default
          errors.push validationError field, blob[field], ' was not present.'

        else if blob[field]? and not validator(blob[field])
          errors.push validationError field, blob[field], ' was not a valid ' + config.schema[field].type

        for field, value of blob when not @_schema[field]? and field isnt 'id' and field not in _(@_schema._assoc).pluck 'name'
          errors.push validationError field, blob[field], ' is not in schema'

      done(if errors.length then {errors} else null)

    # Fetch from id
    @Fetch: (id, done) ->
      @_table.Find id, (err, blob) =>
        return done err if err?

        @resource.Deserialize blob, done

    # Get every records satisfying given constraints
    @FetchBy: (constraints, done) ->
      @_table.FindWhere '*', constraints, (err, blob) =>
        return done err if err?

        @resource.Deserialize blob, done

    # Get every records from db
    @List: (done) ->
      @_table.Select 'id', {}, {}, (err, ids) =>
        return done err if err?

        async.map _(ids).pluck('id'), (item, done) =>
          @resource.Fetch item, done
        , done

    # Get every records satisfying given constraints
    @ListBy: (constraints, done) ->
      @_table.Select 'id', constraints, {}, (err, ids) =>
        return done err if err?

        async.map _(ids).pluck('id'), (item, done) =>
          @resource.Fetch item, done
        , done

    # Deserialize and Save
    @Create: (blob, done) ->
      @Deserialize blob, (err, resource) ->
        return done err if err?

        resource.Save done

    # Pre-Instanciation and associated model retrival
    @Deserialize: (blob, done) ->
      @_Validate blob, true, (err) =>
        return done err if err?

        res = @
        if @_schema?
          @_FetchAssoc blob, (err, blob) ->
            # console.log '@_schema?', @_schema, blob
            done null, new res blob
        else
          done null, new res blob

    @_FetchAssoc: (blob, done) ->
      assocs = {}
      async.each @_schema._assoc, (resource, done) =>
        resource.Get blob, (err, instance) =>
          return done() if err? and config? and config.schema[resource.name].optional
          return done err if err?

          assocs[resource.name] = instance
          done()

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

    #FIXME: split code
    @Init: ->
      @resource = @
      Nodulator.resources[@lname] = @

      if @config? and @config.schema
        @_schema = {_assoc: []}

        for field, description of @config.schema

          do (description) =>

            isArray = false
            if Array.isArray description.type
              isArray = true
              description.type = description.type[0]

            if description.type? and typeof description.type is 'function'
              @_schema._assoc.push
                name: field
                Get: (blob, done) ->
                  if !isArray
                    description.type.Fetch blob[description.localKey], done
                  else
                    async.map blob[description.localKey], (item, done) =>
                      description.type.Fetch.call description.type, item, done
                    , done

            else if description.type?
              if description.default?
                @::[field] = description.default
              @_schema[field] = typeCheck[description.type]
              if isArray
                @_schema[field] = typeCheck.arrayOf description.type

            else if typeof(description) is 'string'
              @_schema[field] = typeCheck[description]

      if @config? and @config.abstract
        @Extend = (name, routes, config) =>
          if config and not config.abstract
            deleteAbstract = true

          config = _(config).extend @config

          if deleteAbstract
            delete config.abstract

          Nodulator.Resource name, routes, config, @

      else if @_routes?
        @routes = new @_routes(@, @app, @config)

      @
  Resource._PrepareResource(table, config, app, routes, name)
