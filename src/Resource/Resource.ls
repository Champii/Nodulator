require! {
  underscore: __
  async
  '../../': N
  validator: Validator
  hacktiv: Hacktiv
  \./ChangeWatcher
  \./Wrappers
  \prelude-ls : {Obj, keys, map, lists-to-obj, filter, intersection, difference, obj-to-pairs, each, is-type, values, capitalize}
  # \async-ls : {callbacks: {bindA}}
  \../Helpers/Debug
}

debug-res = new Debug 'N::Resource', Debug.colors.blue


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

N.Validator = Validator

N.inited = {}

module.exports = (table, config, app, routes, name) ->

  debug-resource = new Debug "N::Resource::#name"
  # debug-resource.Log = debug "N::Resource::#{name}"
  #   ..color = debug.useColors && debug._colors.purple
  #
  # debug-resource.Warn = debug "N::Resource::#{name}::Warn"
  #   ..color = debug.useColors && debug._colors.yellow
  #
  # debug-resource.Error = debug "N::Resource::#{name}::Error"
  #   ..color = debug.useColors && debug._colors.red

  debug-res.Log "Creating new Resource : #name"

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

      debug-resource.Log "Instantiate with {id: #{blob.id}}"

      @_table = @.__proto__.constructor._table
      @_schema = @.__proto__.constructor._schema
      @_type = @.__proto__.constructor.lname

      @id = blob?.id || null

      if @_schema?

        @_schema
          |> obj-to-pairs
          |> filter (-> it.0 of blob)
          |> each (~> @[it.0] =
            | blob[it.0]?   => that
            | it.1.default? => that
            | _             => void)

        @_schema._assoc
          |> each ~>
            # console.log @_schema[it.name].desc
            # desc = @_schema[it.name].desc
            @[it.name] = blob[it.name]
            # console.log @_schema[desc.localKey].desc
            # if not @[it.name]? and (is-type \Array @_schema[desc.localKey].desc or is-type \Array @_schema[desc.localKey].desc?.type)
            # if not @[it.name]? and (is-type \Array @_schema[it.name] or is-type \Array @_schema[it.name]?.type)
              # @[it.name] = []


        @id = blob.id
      else
        import blob

    # Wrap the _SaveUnwrapped() call
    Save: @_WrapFlipDone @_WrapPromise @_WrapDebugError debug-resource~Error, -> @_SaveUnwrapped ...

    # Wrap the _DeleteUnwrapped() call
    Delete: @_WrapFlipDone @_WrapPromise -> @_DeleteUnwrapped ...

    # Get what to send to the database
    Serialize: ->
      res = if @id? then id: @id else {}

      switch
        | @_schema? =>  each (~> res[it] = @[it] if it isnt \_assoc and it not in map (.name), @_schema._assoc), keys @_schema
        | _         =>  each (~> res[it] = @[it] if it[0] isnt \_ and typeof! @[it] isnt 'Function'), keys @

      res

    # Get what to send to client
    ToJSON: ->
      res = @Serialize()

      if @_schema?
        each ~>
          if @[it.name]?
            switch
              | Array.isArray @[it.name] and @[it.name].0?  =>  res[it.name] = __(@[it.name]).invoke 'ToJSON'
              | @[it.name].ToJSON?                          =>  res[it.name] = @[it.name].ToJSON()
        , @_schema._assoc

      # console.log 'ToJSON', @_type, @_schema?._assoc, res if @_type is 'user'
      res

    # Preserve the assocs while extending
    ExtendSafe: (blob) ->
      return __(@).extend blob if not @_schema?

      newBlob = __({}).extend blob

      each (-> delete newBlob[it.name]), @_schema._assoc

      __(@).extend newBlob

    Watch: (done) ->
      N.Watch ~>
        N[capitalize name + \s ].Fetch @id, (err, res) ~>
          return console.log err if err?

          @ <<<< res
          done err, res if done?
      @

  #
  # Private
  # Instance Methods
  #

    # Save without wrap
    _SaveUnwrapped: (done) ->
      serie = @Serialize()
      Resource._Validate serie, true, (err) ~>
        exists = @id?

        if exists => debug-resource.Log "Saving  {id: #{@id}}"
        else      => debug-resource.Log "Saving New"

        switch
          | err? => done err
          | _    =>
            @_table.Save serie, (err, id) ~>
              | err?  =>  done err
              | _     =>
                if !exists
                  @id = id
                  N.bus.emit \new_ + name, @
                else
                  N.bus.emit \update_ + name, @
                ChangeWatcher.Invalidate()

                debug-resource.Log "Saved  {id: #{@id}}"
                done null, @
      @

    # Delete without wrap
    _DeleteUnwrapped: (done) ->
      debug-resource.Log "Deleting  {id: #{@id}}"
      @_table.Delete @id, (err, affected) ~>
        switch
          | err? => done err
          | _    =>
            @id = undefined
            N.bus.emit \delete_ + @name, @
            ChangeWatcher.Invalidate()

            debug-resource.Log "Deleted  {id: #{@id}}"

            done null, @

      null

  #
  # Public
  # Class Methods
  #

    # _Deserialize and Save from a blob or an array of blob
    @Create = @_WrapFlipDone @_WrapPromise @_WrapWatchArgs @_WrapDebugError debug-resource~Error, (args, done, _depth = @config?.maxDepth || @@DEFAULT_DEPTH) ->
      @Init!

      if is-type \Array args
        debug-resource.Log "Creating from array: #{args.length} entries"


      @_HandleArrayArg args, (blob, done) ~>

        debug-resource.Log "Creating"
        @resource._Deserialize blob, (err, instance) ~>
          | err? => done err
          | _    =>
            instance._SaveUnwrapped (err, instance) ~>
              | err? => done err
              | _    =>
                if instance._schema?
                  @_FetchAssoc instance, (err, blob) ~>
                    | err? => done err
                    | _    =>
                      instance import blob
                      debug-resource.Log "Created {id: #{instance.id}}"
                      done null instance
                  , _depth
                else
                  debug-resource.Log "Created {id: #{instance.id}}"
                  done null instance

        , _depth
      , (...args) ->
        # Debug.UnDepth()
        done.apply null, args

    # Fetch from id or id array
    @Fetch = @_WrapFlipDone @_WrapPromise @_WrapWatchArgs @_WrapDebugError debug-resource~Error, ->
      @Init!
      @_FetchUnwrapped ...

    # Fetch from id or id array
    @_FetchUnwrapped = (arg, done, _depth = @config?.maxDepth || @@DEFAULT_DEPTH) ->

      if is-type \Array arg
        debug-resource.Log "Fetching from array: #{arg.length} entries"

      cb = (done) ~> (err, blob) ~>
        | err?  => done err
        | _     =>
          debug-resource.Log "Fetched {id: #{blob.id}}"
          Debug.Depth!
          @resource._Deserialize blob, (err, data)->
            Debug.UnDepth!
            done err, data
          , _depth

      @_HandleArrayArg arg, (constraints, done) ~>

        debug-resource.Log "Fetch #{JSON.stringify constraints}"

        if is-type 'Object', constraints
          @_table.FindWhere '*', constraints, cb done
        else
          @_table.Find constraints, cb done
      , done

    # Get every records from DB
    @List =  @_WrapFlipDone @_WrapPromise @_WrapWatchArgs @_WrapDebugError debug-resource~Error, ->
      @Init!
      @_ListUnwrapped ...

    # Get every records from DB
    @_ListUnwrapped = (arg, done, _depth = @config?.maxDepth || @@DEFAULT_DEPTH) ->

      if typeof(arg) is 'function'
        if typeof(done) is 'number'
          _depth = done

        done = arg
        arg = {}

      if is-type \Array arg
        debug-resource.Log "Listing from array: #{arg.length} entries"
        # Debug.Depth!

      @_HandleArrayArg arg, (constraints, _done) ~>
        done = (err, data) ->
          Debug.UnDepth!
          _done err, data

        debug-resource.Log "List #{JSON.stringify constraints}"
        Debug.Depth!

        @_table.Select '*', (constraints || {}), {}, (err, blobs) ~>
          | err?  => done err?
          | _     =>
            async.map blobs, (blob, done) ~>
              debug-resource.Log "Listed {id: #{blob.id}}"
              @resource._Deserialize blob, done, _depth
            , done

      , done
    # Delete given records from DB
    @Delete = @_WrapFlipDone @_WrapPromise @_WrapDebugError debug-resource~Error, ->
      @Init!
      @_DeleteUnwrapped ...

    # Delete given records from DB
    @_DeleteUnwrapped = (arg, done) ->

      if is-type \Array arg
        debug-resource.Warn "Deleting from array: #{arg.length} entries"

      @_HandleArrayArg arg, (constraints, done) ~>
        debug-resource.Warn "Deleting #{JSON.stringify constraints}"
        @resource._FetchUnwrapped constraints, (err, instance) ~>
          | err?  => done err
          | _     => instance._DeleteUnwrapped done

      , done

    @Watch = (...args) ->

      @Init! if not @inited

      query = {}
      types = []
      done = null
      for arg in args

        if is-type \Function arg
          done := arg
        else if is-type \Object arg
          query := arg
        else if is-type \Array arg
          types := []
        else if is-type \String arg
          types.push arg

      if not types.length
        types.push \all

      for type in types
        if type is 'new'
          N.bus.on 'new_' + name, (item) ->
            done item.Watch! if done?

        else if type is 'changed'
          N.bus.on 'update_' + name, (item) ->
            done item.Watch! if done?
        else if type is 'deleted'
          N.bus.on 'delete_' + name, (item) ->
            done item.Watch! if done?

        else if type is 'all'
          return N.Watch ~>
            N[capitalize name + \s ].List query, (err, res) ~>
              return done err if err?

              done res if done?

      @

  #
  # Private
  # Class Methods
  #


    # Check for schema validity
    @_Validate = (blob, full, done) ->
      return done() if not config? or not config.schema?
      delete blob._id if N.config.dbType is \Mongo

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
        | is-type 'Array', arg => async.mapSeries arg, callback, done
        | _                    => callback arg, done

      @

    # Pre-Instanciation and associated model retrival
    @_Deserialize = (blob, done, _depth = @config?.maxDepth || @@DEFAULT_DEPTH) ->
      @_Validate blob, true, (err) ~>
        return done err if err?

        res = @
        # console.log 'Deserialize', @_type, @_schema
        if @_schema?
          @_FetchAssoc blob, (err, blob) ->
            return done err if err?

            done null, new res blob
          , _depth
        else
         done null, new res blob

    # Get each associated Resource
    i = 0
    @_FetchAssoc = (blob, done, _depth) ->
      assocs = {}

      debug-resource.Log "Fetching #{@_schema._assoc.length} assocs with Depth #{_depth}"
      # Debug.Depth!
      async.eachSeries @_schema._assoc, (resource, _done) ~>
        done = (err, data)->
          # Debug.UnDepth!
          _done err, data

        # console.log resource
        debug-resource.Log "Assoc: Fetching #{resource.name}"
        # Debug.Depth!
        resource.Get blob, (err, instance) ->
          assocs[resource.name] = resource.default if resource.default?
          # console.log blob
          if err?
            debug-resource.Error "Assoc: #{resource.name} #{JSON.stringify err}"

          if err? and resource.type is \distant => done!
          else if err? and config?.schema? => done err
          else if err? and config? and config.schema?[resource.name]?.optional => done!
          else
            assocs[resource.name] = instance
            done!
        , _depth
      , (err) ->
        # Debug.UnDepth!
        return done err if err?

        done null, __.extend blob, assocs

  #
  # Private
  # Init process
  #

    # Prepare the core of the Resource
    @_PrepareResource = (_table, _config, _app, _routes, _name, _parent = null) ->
      debug-res.Log 'Preparing resource'
      @_table = _table
      @config = _config
      @app = _app
      @INITED = false
      @lname = _name.toLowerCase()

      @_routes = _routes
      @_parent = _parent

      @

    # Prepare Relationships
    @_PrepareRelationship = (isArray, field, description) ->
      type = null
      foreign = null
      get = (blob, done) ->
        done new Error 'No local or distant key given'

      debug-res.Log "Preparing Relationships with #{description.type.name}"

      if description.localKey?
        type = \local
        foreign = description.localKey
        get = (blob, done, _depth) ->
          if not _depth
            return done()

          if !isArray
            if not typeCheck.int blob[description.localKey]
              return done new Error 'Model association needs integer as id and key'
          else
            if not typeCheck.array blob[description.localKey]
              return done new Error 'Model association needs array of integer as ids and localKeys'

          description.type._FetchUnwrapped blob[description.localKey], done, _depth - 1

      else if description.distantKey?
        foreign = description.distantKey
        type = \distant
        get = (blob, done, _depth) ->
          if not _depth or not blob.id?
            return done()

          if !isArray
            description.type._FetchUnwrapped {"#{description.distantKey}": blob.id} , done, _depth - 1
          else
            description.type._ListUnwrapped {"#{description.distantKey}": blob.id}, done, _depth - 1

      toPush  =
        type: type
        name: field
        Get: get
        foreign: foreign
      toPush.default = description.default if description.default?
      @_schema._assoc.push toPush

    # Setup Schema
    @_PrepareSchema = ->
      @_schema = {_assoc: []}


      debug-res.Log "Preparing Schema for #{name}"

      for field, description of @config.schema

        isArray = false
        if description.type? and Array.isArray description.type
          isArray = true
          description.type = description.type[0]
        else if Array.isArray description
          isArray = true
          description = description[0]

        if description.type? and typeof description.type is 'function'
          if description.localKey? and not @config.schema[description.localKey]?
            if isArray
              @_schema[description.localKey] = {desc: [\int], typeCheck: typeCheck.arrayOf \int}
              @config.schema[description.localKey] = [\int]
            else
              @_schema[description.localKey] = {desc: \int, typeCheck: typeCheck.int}
              @config.schema[description.localKey] = \int

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
      @Extend = (name, routes, config) ~>
        @Init!

        # config = __(config || {}).extend @config
        config = config with @config

        if config and config.abstract
          deleteAbstract = true

        if deleteAbstract
          delete config.abstract

        N.Resource name, routes, config, @

    # Initialisation
    @Init = (@config = @config, extendArgs) ->
      if @INITED
        return @

      if N.inited[@lname]?
        return @
        throw new Error 'ALREADY INITED !!!! BUUUUUUUUUG' + @lname

      debug-res.Log "Init() #{name}"

      @resource = @

      N.resources[@lname] = @

      if @config? and @config.schema
        @_PrepareSchema()

      @_PrepareAbstract()

      if @_routes?
        @routes = new @_routes(@, @config)

      @INITED = true
      N.inited[@lname] = true

      #FIXME
      N[capitalize @lname + \s] = @

      @

  Resource._PrepareResource(table, config, app, routes, name)
