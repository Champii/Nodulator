require! {
  underscore: __
  async
  '../../': N
  validator: Validator
  hacktiv: Hacktiv
  \./ChangeWatcher
  \./Wrappers
  \./Schema
  \prelude-ls
  # \async-ls : {callbacks: {bindA}}
  \../Helpers/Debug
  \./Cache : cache
  polyparams: ParamWraper
}

debug-res = new Debug 'N::Resource', Debug.colors.blue

global import prelude-ls


N.Validator = Validator

N.inited = {}

module.exports = (table, config, app, routes, name) ->

  debug-resource = new Debug "N::Resource::#name"

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
      @_config = @.__proto__.constructor.config

      import @_schema.Process blob

    # Wrap the _SaveUnwrapped() call
    Save: @_WrapFlipDone @_WrapPromise @_WrapDebugError debug-resource~Error, -> @_SaveUnwrapped ...

    # Wrap the _DeleteUnwrapped() call
    Delete: @_WrapFlipDone @_WrapPromise @_WrapDebugError debug-resource~Error, -> @_DeleteUnwrapped ...

    # Get what to send to the database
    Serialize: ->
      # res = if @id? then id: @id else {}

      @_schema.Filter @

    # Get what to send to client
    ToJSON: ->
      res = @Serialize()


      @_schema.GetVirtuals! |> each ~> res[it.name] = @[it.name]
      each ~>
        if @[it.name]?
          switch
            | Array.isArray @[it.name] and @[it.name].0?  =>  res[it.name] = __(@[it.name]).invoke 'ToJSON'
            | @[it.name].ToJSON?                          =>  res[it.name] = @[it.name].ToJSON()
      , @_schema.assocs

      res

    # Preserve the assocs while extending
    ExtendSafe: (blob) ->
      newBlob = __({}).extend blob

      each (-> delete newBlob[it.name]), @_schema.assocs

      __(@).extend newBlob

    Watch: (done) ->
      N.Watch ~>
        N[capitalize name + \s ].Fetch @id, (err, res) ~>
          return done err if err? and done?
          return console.error err if err?

          @ <<<< res
          done res if done?
      @

  #
  # Private
  # Instance Methods
  #

    # Save without wrap
    _SaveUnwrapped: (config, done) ->
      if not done?
        done = config
        config = @_config

      serie = @Serialize()
      @_schema.Validate serie, (err) ~>
        exists = @id?

        if exists => debug-resource.Log "Saving  {id: #{@id}}"
        else      => debug-resource.Log "Saving New"

        switch
          | err? => done err
          | _    =>
            @_table.Save serie, config, (err, instance) ~>
              | err?  =>  done err
              | _     =>
                if !exists
                  @id = instance.id
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
            cache.Delete @_type + 'Fetch' + @id, ~>
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

    # @Hydrate: (blob) ->
    #
    #   @assocs |> each -> blob[it.name] =  if blob[it.name]?
    #   new @ blob

    # _Deserialize and Save from a blob or an array of blob
    @Create = @_WrapFlipDone @_WrapPromise @_WrapWatchArgs @_WrapDebugError debug-resource~Error, ->
      @Init!
      @_CreateUnwrapped ...

    @_CreateUnwrapped = @_WrapParams do
      * \Object : optional: true
      * \Array : optional: true
      * \Object : optional: true
      * \Function
      * \Number : optional: true
      (arg, args, config, done, _depth = @config?.maxDepth || @@DEFAULT_DEPTH) ->

        if args?
          debug-resource.Log "Creating from array: #{args.length} entries"

        @_HandleArrayArg arg || args || {}, (blob, done) ~>

          debug-resource.Log "Creating"
          @resource._Deserialize blob, (err, instance) ~>
            | err? => done err
            | _    =>
              c = {}
              if config?.dbType or config?.dbAuth
                @_table.AddDriver config
                c = config
              else
                c = @config
              instance._SaveUnwrapped c, (err, instance) ~>
                | err? => done err
                | _    =>
                  if instance._schema.assocs.length
                    @_schema.FetchAssoc instance, (err, blob) ~>
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
        , done
        # , (...args) ->
        #   # Debug.UnDepth()
        #   done.apply err, args

    # Fetch from id or id array
    @Fetch = @_WrapFlipDone @_WrapPromise @_WrapCache 'Fetch' @_WrapWatchArgs @_WrapDebugError debug-resource~Error, ->
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
    @List = @_WrapFlipDone @_WrapPromise @_WrapCache 'List' @_WrapWatchArgs @_WrapDebugError debug-resource~Error, ->
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

      @Init!

      query = {}
      types = []
      done = ->
      for arg in args
        switch
          | is-type \Function arg => done := arg
          | is-type \Array arg    => types := arg
          | is-type \String arg   => types.push arg
          | is-type \Object arg   => query := arg

      if not types.length
        types.push \all

      for type in types
        switch type
          | type in <[new updated deleted]> => N.bus.on type + '_' + name, (item) -> done item.Watch!
          | \all                            => N.Watch ~> @List query .fail done .then done

      @

    @AttachRoute = (@_routes) ->
      @Init!

    @_AddRelationship = (res, isArray, isDistant, isRequired, key, fieldName, prepare = true) ->
      @Init!

      obj = type: res

      if isDistant
        res.Field key, \int .Required isRequired
        obj.distantKey = key
      else
        @Field key, \int .Required isRequired
        obj.localKey = key

      if prepare
        @_schema.PrepareRelationship isArray, capitalize(fieldName + if isArray => 's' else ''), obj

    @HasOne = @_WrapParams do
      * \Function
      * \Boolean : default: true
      * \String : optional: true
      * \String : optional: true
      (res, belongsTo, fieldName, key) ->
        @_AddRelationship res, false, true, true, key || @lname + \Id , fieldName || res.lname
        res.BelongsTo @, @lname, key || @lname + \Id if belongsTo

    @HasMany = @_WrapParams do
      * \Function
      * \Boolean : default: true
      * \String : optional: true
      * \String : optional: true
      (res, belongsTo, fieldName, key) ->
        @_AddRelationship res, true, true, true, key || @lname + \Id , fieldName || res.lname
        res.BelongsTo @, @lname, key || @lname + \Id if belongsTo

    @BelongsTo = @_WrapParams do
      * \Function
      * \String : optional: true
      * \String : optional: true
      (res, fieldName, key) ->
        @_AddRelationship res, false, false, true, key || res.lname + \Id , fieldName || res.lname

    # TO BE TESTED

    # @MayHasOne = (res, belongsTo = true) ->
    #   @_AddRelationship res, false, true, false
    #   res.MayBelongsTo @ if belongsTo
    #
    # @MayHasMany = (res, belongsTo = true) ->
    #   @_AddRelationship res, true, true, false
    #   res.MayBelongsTo @ if belongsTo
    #
    # @MayBelongsTo = (res) ->
    #   @_AddRelationship res, false, false, false

    @HasOneThrough = (res, through) ->
      @HasOne through
      through.HasOne res
      @_schema.HasOneThrough res, through

    @HasManyThrough = (res, through) ->
      @HasMany through
      res.HasMany through
      @_schema.HasManyThrough res, through

    @HasAndBelongsToMany = (res, reverse = true) ->
      names = sort [@lname, res.lname]
      Assoc = N names.0 + \s_ + names.1, @config .Init!
      @_schema.HasAndBelongsToMany res, Assoc
      res._schema.HasAndBelongsToMany @, Assoc if reverse

    @Field = (...args) ->
      @Init!
      @_schema.Field.apply @_schema, args

    Add: @_WrapPromise (instance, done) ->
      names = sort [@_type, instance._type]
      res = __(@_schema.habtm).findWhere lname: names.0 + \s_ + names.1
      res.Create {"#{@_type}Id": @id, "#{instance._type}Id": instance.id}, (err, newRes) ->
        done err, instance
      #
      #   done err

    Remove: @_WrapPromise (instance, done) ->
      names = sort [@_type, instance._type]
      res = __(@_schema.habtm).findWhere lname: names.0 + \s_ + names.1
      res.Delete {"#{@_type}Id": @id, "#{instance._type}Id": instance.id}, (err, newRes) ->
        done err, instance
  #
  # Private
  # Class Methods
  #

    # Wrapper to allow simple variable or array as first argument
    @_HandleArrayArg = (arg, callback, done) ->
      do ->
        | is-type 'Array', arg => async.mapSeries arg, callback, done
        | _                    => callback arg, done

      @

    # Pre-Instanciation and associated model retrival
    @_Deserialize = (blob, done, _depth = @config?.maxDepth || @@DEFAULT_DEPTH) ->
      @_schema.Validate blob, (err) ~>
        return done err if err?

        res = @

        if @_schema.assocs.length
          @_schema.FetchAssoc blob, (err, blob) ->
            return done err if err?

            done null, new res blob
          , _depth
        else
          done null, new res blob

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
      @_schema = new Schema @lname, _config?.schema

      @_routes = _routes
      @_parent = _parent

      @

    # Prepare Relationships

    # Setup Schema
    # @_PrepareSchema = ->
    #   debug-res.Log "Preparing Schema for #{name}"
    #
    #   for field, description of @config.schema
    #
    #     isArray = false
    #     if description.type? and Array.isArray description.type
    #       isArray = true
    #       description.type = description.type[0]
    #     else if Array.isArray description
    #       isArray = true
    #       description = description[0]
    #
    #     if typeof(description) is 'function'
    #       @Field field, null .Virtual description
    #
    #     else if description.type? and typeof description.type is 'function'
    #       if description.localKey? and not @config.schema[description.localKey]?
    #         if isArray
    #           @Field description.localKey, [\int]
    #         else
    #           @Field description.localKey, \int
    #
    #       # @_PrepareRelationship isArray, field, description
    #
    #     else if description.type?
    #       if description.default?
    #         if typeof(description.default) is 'function'
    #           @::[field] = description.default()
    #         else
    #           @::[field] = description.default
    #
    #       @Field field, description.type
    #
    #       if isArray
    #         @Field field, [description.type]
    #
    #     else if typeof(description) is 'string'
    #       if isArray
    #         @Field field, [description]
    #       else
    #         @Field field, description

    # Setup inheritance
    # @_PrepareAbstract = ->
    @Extend = (name, routes, config) ->
      @Init!

      config = __(config || {}).extend @config
      # config = config with @config

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

      @resource = @

      N.resources[@lname] = @

      debug-res.Log "Init() #{@lname}"

      N.inited[@lname] = true

      @INITED = true

      if @_routes?
        @routes = new @_routes(@, @config)

      # if @config? and @config.schema
      #   @_PrepareSchema()

      # @_PrepareAbstract()

      #FIXME
      N[capitalize @lname + \s] = @

      @

  Resource._PrepareResource(table, config, app, routes, name)
