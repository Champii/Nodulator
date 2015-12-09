require! {
  '../../': N
  \./ChangeWatcher
  \./Schema
  \prelude-ls
  \../Helpers/Debug
  \./Connectors : DB
  async
  underscore: __
  validator: Validator
  hacktiv: Hacktiv
  polyparams: ParamWraper
}

cache = null
Wrappers = null

debug-res = new Debug 'N::Resource', Debug.colors.blue

global import prelude-ls

N.Validator = Validator

N.inited = {}

module.exports = (config, routes, name) ->

  if not cache?
    cache := require \./Cache
  if not Wrappers?
    Wrappers := require \./Wrappers

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

      @_table = @.__proto__.constructor._table
      @_schema = @.__proto__.constructor._schema
      @_type = @.__proto__.constructor.lname
      @_config = @.__proto__.constructor.config

      if blob.promise?
        debug-resource.Log "Defered instanciation"
        @_d = blob
        @_promise = blob.promise
        return


      debug-resource.Log "Instantiate with {id: #{blob.id}}"

      import @_schema.Populate @, blob

    _WrapReturnThis: (done) ->
      (arg) ~>
        res = done arg
        res?._promise || res || arg

    Then: ->
      @_promise = @_promise.then @_WrapReturnThis it if @_promise?
      @
    #
    Catch: ->
      @_promise = @_promise.catch @_WrapReturnThis it if @_promise?
      @

    Fail: ->
      @_promise = @_promise.fail @_WrapReturnThis it if @_promise?
      @

    # Wrap the _SaveUnwrapped() call
    Save: @_WrapFlipDone @_WrapPromise @_WrapResolvePromise @_WrapDebugError debug-resource~Error, -> @_SaveUnwrapped ...

    # Wrap the _DeleteUnwrapped() call
    Delete: @_WrapFlipDone @_WrapPromise @_WrapResolvePromise @_WrapDebugError debug-resource~Error, -> @_DeleteUnwrapped ...

    # Get what to send to the database
    Serialize: ->
      @_schema.Filter @

    # Get what to send to client
    ToJSON: ->
      res = @Serialize()

      res = @_schema.RemoveInternals res
      res <<< @_schema.GetVirtuals @
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

    # Watch the instance refetch itself
    Watch: @_WrapResolvePromise (done) ->
      N.Watch ~>
        @Fetch (err, res) ~>
          return done err if err? and done?
          return console.error err if err?

          @ <<<< res
          done @ if done?
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
              N.bus.emit \delete_ + name, @

              ChangeWatcher.Invalidate()

              debug-resource.Log "Deleted  {id: #{@id}}"

              done null, @

      @

  #
  # Public
  # Class Methods
  #

    # Populate an existing instance with a new blob
    @Hydrate = (blob) ->

      res = new @ blob

      @_schema.assocs |> each ->
        if blob[it.name]?
          if is-type \Array blob[it.name]
            res[it.name] = blob[it.name] |> map (it.type~Hydrate)
          else
            res[it.name] = it.type.Hydrate blob[it.name]

      res

    # _Deserialize and Save from a blob or an array of blob
    @Create = @_WrapFlipDone @_WrapPromise @_WrapWatchArgs @_WrapDebugError debug-resource~Error, ->
      @Init!
      @_CreateUnwrapped ...

    # Create without wraps
    @_CreateUnwrapped = @_WrapParams do
      * \Object : optional: true
      * \Array : optional: true
      * \Object : optional: true
      * \Function
      * \Number : optional: true
      (arg, args, config, done, _depth = if @config?.maxDepth? => @config.maxDepth else @@DEFAULT_DEPTH) ->

        if args?
          debug-resource.Log "Creating from array: #{args.length} entries"

        @_HandleArrayArg arg || args || {}, (blob, done) ~>

          async.mapSeries obj-to-pairs(blob), (pair, done) ~>
            if pair.0 in (@_schema.assocs |> map (.foreign)) and pair.1?._promise
              pair.1.Then -> done null [pair.0, it.id]
              pair.1.Catch done
            else
              done null, pair
          , (err, results) ~>
            return done err if err?

            blob = pairs-to-obj results

            debug-resource.Log "Creating #{JSON.stringify blob}"
            @resource._Deserialize blob, (err, instance) ~>
              | err? => done err
              | _    =>
                c = {}
                if config?.db?
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

    # Fetch from id or id array
    @Fetch = @_WrapFlipDone @_WrapPromise @_WrapCache 'Fetch' @_WrapWatchArgs @_WrapDebugError debug-resource~Error, ->
      @Init!
      @_FetchUnwrapped ...

    # Fetch from id or id array
    @_FetchUnwrapped = (arg, done, _depth = if @config?.maxDepth? => @config.maxDepth else @@DEFAULT_DEPTH) ->

      if is-type \Array arg
        debug-resource.Log "Fetching from array: #{arg.length} entries"

      cb = (done) ~> (err, blob) ~>
        | err?  => done err
        | _     =>
          debug-resource.Log "Fetched {id: #{blob.id}}"
          Debug.Depth!
          @resource._Deserialize blob, done, _depth

      @_HandleArrayArg arg, (constraints, done) ~>

        debug-resource.Log "Fetch #{JSON.stringify constraints}"

        if is-type 'Object', constraints
          @_table.FindWhere '*', constraints, cb done
        else
          @_table.Find constraints, cb done
      , done

    # Get a list of records from DB
    @List = @_WrapFlipDone @_WrapPromise @_WrapCache 'List' @_WrapWatchArgs @_WrapDebugError debug-resource~Error, ->
      @Init!
      @_ListUnwrapped ...

    # Get a list of records from DB
    @_ListUnwrapped = (arg, done, _depth = if @config?.maxDepth? => @config.maxDepth else @@DEFAULT_DEPTH) ->

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

    # Watch the Resource for a particular event or any changes
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
        switch
          | type in <[new update delete]>   => N.bus.on type + '_' + name, done
          | \all                            => N.Watch ~> @List query .Then done .Catch done

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
      * \Boolean : default: true
      (res, belongsTo, fieldName, key, may) ->
        @_AddRelationship res, false, true, may, key || @lname + \Id , fieldName || res.lname
        res.BelongsTo @, fieldName || @lname, key || @lname + \Id , may if belongsTo
        @

    @HasMany = @_WrapParams do
      * \Function
      * \Boolean : default: true
      * \String : optional: true
      * \String : optional: true
      * \Boolean : default: true
      (res, belongsTo, fieldName, key, may) ->
        @_AddRelationship res, true, true, may, key || @lname + \Id , fieldName || res.lname
        res.BelongsTo @, fieldName || @lname, key || @lname + \Id , may if belongsTo
        @

    @BelongsTo = @_WrapParams do
      * \Function
      * \String : optional: true
      * \String : optional: true
      * \Boolean : default: true
      (res, fieldName, key, may) ->
        @_AddRelationship res, false, false, may, key || res.lname + \Id , fieldName || res.lname
        @

    @MayHasOne = @_WrapParams do
      * \Function
      * \Boolean : default: true
      * \String : optional: true
      * \String : optional: true
      * \Boolean : default: false
      (...args) -> @HasOne.apply @, args

    @MayHasMany = @_WrapParams do
      * \Function
      * \Boolean : default: true
      * \String : optional: true
      * \String : optional: true
      * \Boolean : default: false
      (...args) -> @HasMany.apply @, args

    @MayBelongsTo = @_WrapParams do
      * \Function
      * \String : optional: true
      * \String : optional: true
      * \Boolean : default: false
      (...args) -> @BelongsTo.apply @, args

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

    Fetch: @_WrapPromise @_WrapResolveArgPromise (done) ->
      N[capitalize @_type].Fetch @id, done

    Add: @_WrapPromise @_WrapResolvePromise @_WrapResolveArgPromise  (instance, done) ->

      names = sort [@_type, instance._type]
      res = @_schema.habtm |> find (.lname is names.0 + \s_ + names.1)
      if res?
        return res._CreateUnwrapped {"#{@_type}Id": @id, "#{instance._type}Id": instance.id}, (err, newRes) ~>
          return done err if err?

          @_SaveUnwrapped ~>
            return done it if it?

            @Fetch done

      res = @_schema.assocs |> find (.type.lname is instance._type)
      if res?
        if res.keyType is \distant
          instance[res.foreign] = @id
          instance._SaveUnwrapped ~>
            return done it if it?

            @Fetch done

        else if res.keyType is \local
          @[res.foreign] = instance.id
          @_SaveUnwrapped ~>
            return done it if it?

            @Fetch done
      else
        done new Error "#{capitalize @_type}: Add: No assocs found for #{capitalize instance._type}"

    Remove: @_WrapPromise @_WrapResolvePromise @_WrapResolveArgPromise (instance, done) ->
      names = sort [@_type, instance._type]
      res = __(@_schema.habtm).findWhere lname: names.0 + \s_ + names.1
      if res?
        return res.Delete {"#{@_type}Id": @id, "#{instance._type}Id": instance.id}, (err, newRes) ->
          done err, instance

      res = @_schema.assocs |> find (.type.lname is instance._type)
      if res?
        if res.keyType is \distant
          instance[res.foreign] = null
          instance._SaveUnwrapped ~>
            return done it if it?

            @Fetch done

        else if res.keyType is \local
          @[res.foreign] = null
          @_SaveUnwrapped ~>
            return done it if it?

            @Fetch done
      else
        done new Error "#{capitalize @lname}: Add: No assocs found for #{capitalize instance.lname}"

    # Change properties and save
    Set: @_WrapPromise @_WrapResolvePromise (obj, done) ->
      if is-type \Function obj
        fun = ~>
          obj.call @, @
          @

        @ExtendSafe fun!
      else
        @ExtendSafe obj
      @Save done

    Log: @_WrapPromise @_WrapResolvePromise ->

      console.log 'tamere', @
      console.log @ToJSON!
      it null @

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
    @_Deserialize = (blob, done, _depth) ->
      res = @

      if @_schema.assocs.length
        @_schema.FetchAssoc blob, (err, blob) ->
          return done err if err?

          done null, new res blob
        , _depth - 1
      else
        done null, new res blob

  #
  # Private
  # Init process
  #

    # Prepare the core of the Resource
    @_PrepareResource = (_config, _routes, _name, _parent = null) ->
      debug-res.Log 'Preparing resource'

      @lname = _name.toLowerCase()

      @_table = new DB @lname + \s
      if not _config?.abstract
        @_table.AddDriver _config
      else if not _config? or (_config? and not _config.abstract)
        @_table.AddDriver @config

      @config = _config
      @INITED = false

      @_schema = new Schema @lname, _config?.schema
      @_parent = _parent
      if @_parent?
        @_schema <<< @_parent._schema.Inherit!

      @_schema.Resource = @

      @Route = _routes
      @_routes = _routes

      @

    # Setup inheritance
    @Extend = (name, routes, config) ->
      @Init!

      config = config || @config

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

      #FIXME
      N[capitalize @lname] = @

      @

  Resource._PrepareResource(config, routes, name)
