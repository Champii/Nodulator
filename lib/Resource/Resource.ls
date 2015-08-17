require! {
  underscore: __
  async
  '../../': Nodulator
  validator: Validator
  hacktiv: Hacktiv
  \../ChangeWatcher
  \./Wrappers
  \prelude-ls : {Obj, keys, map, lists-to-obj, filter, intersection, difference, obj-to-pairs, each, is-type, values}
  \async-ls : {callbacks: {bindA}}
}

validationError = (field, value, message) ->
  field: field
  value: value
  message: "The '#field' field with value '#value' #message"

typeCheck =
  bool: (value) -> typeof(value) isnt 'string' and '' + value is 'true' or '' + value is 'false'
  int: Validator.isInt
  string: (value) -> true # FIXME: call add subCheckers
  date: Validator.isDate
  email: Validator.isEmail
  array: (value) -> Array.isArray value
  arrayOf: (type) -> (value) ~> not __(map (@[type]), value).contains (item) -> item is false

Nodulator.Validator = Validator

module.exports = (table, config, app, name) ->

  error = new Hacktiv.Value

  class Resource extends Wrappers

    @DEFAULT_DEPTH = 1
    @INITED = false
    @error = error
    @_schema = null

  #
  # Public
  # Instance Methods
  #

    # Constructor
    (blob) ->
      @_table = @@_table
      @_schema = @@_schema
      @_type = @@lname

      @id = blob?.id || null

      if @_schema?

        @_schema
          |> obj-to-pairs
          |> filter (-> it.0 of blob)
          |> each (~> @[it.0] = blob[it.0] || it.1.default || void)

        each (~> @[it.name] = blob[it.name]), @_schema._assoc

        @id = blob.id
      else
        import blob

      # console.log 'ctor?', @

    # Wrap the _SaveUnwrapped() call
    Save: @_WrapFlipDone @_WrapPromise -> @_SaveUnwrapped ...

    # Wrap the _DeleteUnwrapped() call
    Delete: @_WrapFlipDone @_WrapPromise (...args) -> @_DeleteUnwrapped ...

    # Get what to send to the database
    Serialize: ->
      res = if @id? then id: @id else {}

      switch true
        | @_schema? =>  each (~> res[it] = @[it] if it isnt \_assoc), keys @_schema
        | _         =>  each (~> res[it] = @[it] if it[0] isnt \_ and typeof! @[it] isnt 'Function'), keys @

      res

    # Get what to send to client
    ToJSON: ->
      res = @Serialize()

      if @_schema?
        map ~>
          if @[it.name]?
            match Array.isArray @[it.name]
            | true  =>  res[it.name] = __(@[it.name]).invoke 'ToJSON'
            | false =>  res[it.name] = @[it.name].ToJSON()
        , @_schema._assoc

      res

    # Preserve the assocs while extending
    ExtendSafe: (blob) ->
      return __(@).extend blob if not @_schema?

      newBlob = __({}).extend blob

      for assoc in @_schema._assoc
        delete newBlob[assoc.name]

      __(@).extend newBlob

  #
  # Private
  # Instance Methods
  #

    # Save without wrap
    _SaveUnwrapped: (done) ->
      Resource._Validate @Serialize(), true, (err) ~>
        exists = @id?
        switch true
          | err? => done err
          | _    =>
            # console.log 'tamere', @
            @_table.Save @Serialize(), (err, id) ~> switch true
              | err?  =>  done err
              | _     =>

                if !exists
                  @id = id
                  Nodulator.bus.emit \new_ + name, @ToJSON()
                else
                  Nodulator.bus.emit \update_ + name, @ToJSON()
                ChangeWatcher.Invalidate()

                done null, @
      @

    # Delete without wrap
    _DeleteUnwrapped: (done) ->
      @_table.Delete @id, (err, affected) ~>
        switch true
          | err? => done err
          | _    =>
            Nodulator.bus.emit \delete_ + @name, @ToJSON()
            ChangeWatcher.Invalidate()
            done null, {}

      null

  #
  # Public
  # Class Methods
  #

    # _Deserialize and Save from a blob or an array of blob
    @Create = @_WrapFlipDone @_WrapPromise (args, done, _depth = @config?.maxDepth || @@DEFAULT_DEPTH) ->
      @Init! if not @INITED

      @_HandleArrayArg args, (blob, done) ~>

        # (bindA @resource._Deserialize blob, ((instance, done) -> instance._SaveUnwrapped done))(done)
        @resource._Deserialize blob, (err, instance) ->
          # console.log instance
          switch true
            | err? => done err
            | _    => instance._SaveUnwrapped done
        , _depth
      , done

    # Fetch from id or id array
    @Fetch = @_WrapFlipDone @_WrapPromise @_WrapWatchArgs ->
      console.log 'Fetch wrapped', @INITED, @
      # @resource = @
      @Init! if not @INITED
      # console.log 'Fetch Unwrapped', @INITED
      # console.log \unwraped, args, @
      @_FetchUnwrapped ...

    # Fetch from id or id array
    @_FetchUnwrapped = (arg, done, _depth = @config?.maxDepth || @@DEFAULT_DEPTH) ->

      cb = (done) ~> (err, blob) ~>
        switch true
          | err?  =>
            done err
          | _     =>
            @resource._Deserialize blob, done, _depth

      @_HandleArrayArg arg, (constraints, done) ~> switch constraints
        | is-type 'Object'  => @_table.FindWhere '*', constraints, cb done
        | _                 => @_table.Find constraints, cb done
      , done

    # Get every records from DB
    @List = @_WrapFlipDone @_WrapPromise @_WrapWatchArgs (arg, done, _depth = @config?.maxDepth || @@DEFAULT_DEPTH) ->
      @Init! if not @INITED

      if typeof(arg) is 'function'
        if typeof(done) is 'number'
          _depth = done

        done = arg
        arg = {}


      @_HandleArrayArg arg, (constraints, done) ~>
        @_table.Select '*', (constraints || {}), {}, (err, blobs) ~> switch true
          | err?  => done err?
          | _     =>
            async.map blobs, (blob, done) ~>
              @resource._Deserialize blob, done, _depth
            , done

      , done

    # Delete given records from DB
    @Delete = @_WrapFlipDone @_WrapPromise (arg, done) ->
      @Init! if not @INITED

      @_HandleArrayArg arg, (constraints, done) ~>
        @resource._FetchUnwrapped constraints, (err, instance) ~>
          switch true
            | err?  => done err
            | _     => instance._DeleteUnwrapped done

      , done

  #
  # Private
  # Class Methods
  #

    # Check for schema validity
    @_Validate = (blob, full, done) ->
      return done() if not config? or not config.schema?

      if not done?
        done = full
        full = false

      errors = []

      @_schema
      |> obj-to-pairs
      |> filter (-> it.1? and it.0 isnt '_assoc')
      |> each (~>
        if full and
            not blob[it.0]? and
            not config?.schema?[it.0]?.optional and
            not config?.schema?[it.0]?.default

          errors[*] = validationError it.0, blob[it.0], ' was not present.'

        else if blob[it.0]? and not (it.1)(blob[it.0])

          errors[*] = validationError it.0,
                                      blob[it.0],
                                      ' was not a valid ' + config.schema[it.0].type

        for field, value of blob when not @_schema[field]? and
                                      field isnt \id and
                                      field not in __(@_schema._assoc).pluck \name

          errors.push validationError field, blob[field], ' is not in schema')

      done(if errors.length then {errors} else null)

    # Wrapper to allow simple variable or array as first argument
    @_HandleArrayArg = (arg, callback, done) ->
      do ->
        match arg
          | is-type 'Array' => async.map arg, callback, done
          | _               => callback arg, done

      # Returs this to avoid writing it in every call
      @

    # Pre-Instanciation and associated model retrival
    @_Deserialize = (blob, done, _depth = @config?.maxDepth || @@DEFAULT_DEPTH) ->
      # @Init! if not @@INITED

      @_Validate blob, true, (err) ~>
        return done err if err?

        res = @
        switch true
          | @_schema?   =>
            @_FetchAssoc blob, (err, blob) -> switch true
              | err?    => done err
              | _       => done null, new res blob
            , _depth
          | _           => done null, new res blob

    # Get each associated Resource
    @_FetchAssoc = (blob, done, _depth) ->
      assocs = {}

      async.each @_schema._assoc, (resource, done) ~>
        resource.Get blob, (err, instance) ->
          assocs[resource.name] = resource.default if resource.default?
          switch true
            | err? and config?.schema?  => done err
            | err? and config? and config.schema?[resource.name]?.optional => done!
            | _                         =>
              assocs[resource.name] = instance
              done!
        , _depth
      , (err) -> switch true
        | err?  => done err
        | _     => done null, __.extend blob, assocs

  #
  # Private
  # Init process
  #

    # Prepare the core of the Resource
    @_PrepareResource = (_table, _config, _app, _name) ->
      @_table = _table
      @config = _config
      @app = _app
      @lname = _name.toLowerCase()

      # if _routes?
      # @routes = new _routes(@, @config)

      @

    # Prepare Relationships
    @_PrepareRelationship = (isArray, field, description) ->
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

    # Setup Schema
    @_PrepareSchema = ->
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

    # Setup inheritance
    @_PrepareAbstract = ->
      @Extend = (name, config) ~>
        # @Init! if not @INITED
        if config and not config.abstract
          deleteAbstract = true

        config = __(config).extend @config

        if deleteAbstract
          delete config.abstract

        Nodulator.Resource name, config, @

    # Initialisation
    @Init = (@config = @config, extendArgs) ->
      # console.log @INITED

      return if @INITED

      @resource = @
      # @routes = new routes(@, @config)
      # console.log \Init, @
      # @routes.resource = @ if @routes?
      # console.log 'INIT', @name, @resource
      Nodulator.resources[@lname] = @

      if @config? and @config.schema
        @_PrepareSchema()

      #if @config? and @config.abstract
      @_PrepareAbstract()

      @INITED = true

      @

  Resource._PrepareResource(table, config, app, name)
