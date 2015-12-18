require! {
  \./Helpers/ChangeWatcher
  \./Schema
  \prelude-ls
  \./Helpers/Debug
  async
  underscore: __
  validator: Validator
  hacktiv: Hacktiv
  polyparams: ParamWraper
}

cache = null
Wrappers = null


if not cache?
  cache := require \./Helpers/Cache
if not Wrappers?
  Wrappers := require \./Helpers/Wrappers

error = new Hacktiv.Value

# N = null
module.exports = (config, routes, name, N) ->
  # if not N?
  #   N := _N
    # N.Validator = Validator
    # N.inited = {}

  debug-res = new Debug 'N::Resource', Debug.colors.blue
  debug-resource = new Debug "N::Resource::#name"
  class Resource extends Wrappers
    @N = N
    @watchers = []


    @DEFAULT_DEPTH = 1
    @INITED = false
    @_schema = null
    @error = error
    @debug-resource = debug-resource
    @debug-res = debug-res
    @debug-res.Log "Creating new Resource : #name"

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
    Save: @_WrapPromise @_WrapResolvePromise @_WrapDebugError @debug-resource~Error, -> @_SaveUnwrapped ...

    # Wrap the _DeleteUnwrapped() call
    Delete: @_WrapPromise @_WrapResolvePromise @_WrapDebugError @debug-resource~Error, -> @_DeleteUnwrapped ...

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
      for k, v of newBlob
        if k.0 is \_
          delete newBlob[k]

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
    _SaveUnwrapped: (config, done) -> ...

    # Delete without wrap
    _DeleteUnwrapped: (done) -> ...

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
    @Create = @_WrapPromise @_WrapWatchArgs @_WrapDebugError @debug-resource~Error, ->
      @Init!
      @_CreateUnwrapped ...

    # Create without wraps
    @_CreateUnwrapped = -> ...

    # Fetch from id or id array
    @Fetch = @_WrapPromise @_WrapCache 'Fetch' @_WrapWatchArgs @_WrapDebugError @debug-resource~Error, ->
      @Init!
      @_FetchUnwrapped ...

    # Fetch from id or id array
    @_FetchUnwrapped = -> ...

    # Get a list of records from DB
    @List = @_WrapPromise @_WrapCache 'List' @_WrapWatchArgs @_WrapDebugError @debug-resource~Error, ->
      @Init!
      @_ListUnwrapped ...

    # Get a list of records from DB
    @_ListUnwrapped = -> ...

    # Delete given records from DB
    @Delete = @_WrapPromise @_WrapDebugError @debug-resource~Error, ->
      @Init!
      @_DeleteUnwrapped ...

    # Delete given records from DB
    @_DeleteUnwrapped = -> ...

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
      @routes = new @_routes(@, @config)

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
      delete blob._id if N.config.dbType is \Mongo

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
    @_PrepareResource = -> ...

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
      # if N.inited[@lname]?
      #   return @
      #   throw new Error 'ALREADY INITED !!!! BUUUUUUUUUG' + @lname

      @resource = @

      N.resources[@lname] = @

      @debug-res.Log "Init() #{@lname}"

      N.inited[@lname] = true

      @INITED = true

      # if @_routes?
      #   @routes = new @_routes(@, @config)

      #FIXME
      N[capitalize @lname] = @

      @
