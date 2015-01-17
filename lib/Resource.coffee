_ = require 'underscore'
async = require 'async'

Nodulator = require '../'
Validator = require 'validator'

validationError = (field, value, message) ->
  field: field,
  value: value,
  message: 'The "' + field + '" field' + message

typeCheck =
  bool: (value) -> value is true or value is false
  int: Validator.isInt
  string: (value) -> true # FIXME: call add subCheckers
  date: Validator.isDate
  email: Validator.isEmail

module.exports = (table, config, app, routes, name) ->

  class Resource

    @_description = {}

    constructor: (blob) ->
      @table = @.__proto__.constructor.table

      for field, description in @_description
        if field in blob
          object[field] = blob[field]

    Save: (done) ->
      exists = @id?

      @table.Save @Serialize(), (err, id) =>
        return done err if err?

        if !exists
          @id = id
          Nodulator.bus.emit 'new_' + name, @Serialize()
        else
          Nodulator.bus.emit 'update_' + name, @Serialize()

        done null, @

    Delete: (done) ->
      @table.Delete @id, (err) =>
        return done err if err?
        Nodulator.bus.emit 'delete_' + name, @Serialize()
        done()

    # Send to the database
    Serialize: ->
      res = if @id? then {id: @id} else {}
      for field, description in @_description
        if description.type is 'association'
          if 'many' in description and description.many is true
            res[field] = _(object[field]).invoke("Serialize")
          else
            res[field] = object[field].Serialize()
        else
          res[field] = object[field]
      res

    ToJSON: ->
      @Serialize()

    Validate: (done) ->
      errors = []
      for field, description in @_description
        if 'required' in description and
          description['required'] is true and not @[field]?
          errors.push (validationError field, null, ' was not found and is not optional')
          continue
    
        if description.type in typeCheck and !typeCheck[description.type] @[field]
            errors.push
              validationError field, @[field], ' was not a valid ' + description.type

        else if description.type == 'association'
          Resource.fromDescription[field] (err, blob) ->
            # FIXME : add it or not?
            # This checks if the associated resource exists in database.
            #if err? and err.status == 'not_found'
            #  errors.push
            #    validationError field, @[field], ' could not be found in database.'
            #  continue

            # FIXME : not sure
            if 'unique' in description
              errors.push
                validationError field, @[field], ' was already recorded in database.'

      # FIXME : throw 'unknown type validation'?
      done if errors.length then {errors} else null, blob

    @Fetch: (id, done) ->
      @table.Find id, (err, blob) =>
        return done err if err?

        @resource.Deserialize blob, done

    @FetchBy: (field, value, done) ->
      fieldDict = {}
      fieldDict[field] = value
      @table.FindWhere '*', fieldDict, (err, blob) =>
        return done err if err?

        @resource.Deserialize blob, done

    # FIXME : test
    @ListBy: (field, value, done) ->
      fieldDict = {}
      fieldDict[field] = value
      @table.Select 'id', fieldDict, {}, (err, ids) =>
        return done err if err?

        async.map _(ids).pluck('id'), (item, done) =>
          @resource.Fetch item, done
        , done

    @List: (done) ->
      @table.Select 'id', {}, {}, (err, ids) =>
        return done err if err?

        async.map _(ids).pluck('id'), (item, done) =>
          @resource.Fetch item, done
        , done

    # Fetch from database
    @Deserialize: (blob, done) ->
     async.auto Resource.fromDescription, (err, results) ->
      return done err if err?

      done null, new Resource _.extend(blob, results)

    @_PrepareResource: (_table, _config, _app, _routes, _name) ->
      @table = _table
      @config = _config
      @app = _app
      @lname = _name.toLowerCase()
      @resource = @
      @_routes = _routes

      @fromDescription = {}
      for field, description in @_description
        # FIXME : do some checks, throw some exceptions about description content?
        #         if description.type not present or description.resource
        if 'type' in description and description.type is 'association'
          if 'fetch_by' in description
            @fromDescription[field] = (done, results) ->
              description.resource.FetchBy description['fetch_by'], @[field], done
          else
            @fromDescription[field] = (done, results) ->
              description.resource.Fetch @[field], done

      @

    @Init: ->
      @resource = @
      Nodulator.resources[@lname] = @

      if @config? and @config.abstract
        @Extend = (name, routes, config) =>
          Nodulator.Resource name, routes, config, @
      else if @_routes?
        @routes = new @_routes(@, @app, @config)

  Resource._PrepareResource(table, config, app, routes, name)
