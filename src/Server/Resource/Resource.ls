require! {
  '../Nodulator': N
  \../../Common/Helpers/ChangeWatcher
  \../../Common/Schema
  \prelude-ls
  \../../Common/Helpers/Debug
  \./Connectors : DB
  async
  underscore: __
  validator: Validator
  hacktiv: Hacktiv
  polyparams: ParamWraper
}

cache = null
if not cache?
  cache := require(\../../Common/Helpers/Cache)(N.config)
Wrappers = null

N.Validator = Validator

module.exports = (config, routes, name, N) ->

  debug-resource = null

  class ResourceServer extends require(\../../Common/Resource)(config, routes, name, N)
    @N = N
    debug-resource = @debug-resource

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

    # Create without wraps
    @_CreateUnwrapped = @_WrapParams do
      * \Object : optional: true
      * \Array : optional: true
      * \Object : optional: true
      * \Function
      * \Number : optional: true
      (arg, args, config, done, _depth = if @config?.maxDepth? => @config.maxDepth else @@DEFAULT_DEPTH) ->

        if args?
          @debug-resource.Log "Creating from array: #{args.length} entries"

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

            @debug-resource.Log "Creating #{JSON.stringify blob}"
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
                          @debug-resource.Log "Created {id: #{instance.id}}"
                          done null instance
                      , _depth
                    else
                      @debug-resource.Log "Created {id: #{instance.id}}"
                      done null instance

            , _depth
        , done

    # Fetch from id or id array
    @_FetchUnwrapped = (arg, done, _depth = if @config?.maxDepth? => @config.maxDepth else @@DEFAULT_DEPTH) ->

      if is-type \Array arg
        @debug-resource.Log "Fetching from array: #{arg.length} entries"

      cb = (done) ~> (err, blob) ~>
        | err?  => done err
        | _     =>
          @debug-resource.Log "Fetched {id: #{blob.id}}"
          Debug.Depth!
          @resource._Deserialize blob, done, _depth

      @_HandleArrayArg arg, (constraints, done) ~>

        @debug-resource.Log "Fetch #{JSON.stringify constraints}"

        if is-type 'Object', constraints
          @_table.FindWhere '*', constraints, cb done
        else
          @_table.Find constraints, cb done
      , done

    # Get a list of records from DB
    @_ListUnwrapped = (arg, done, _depth = if @config?.maxDepth? => @config.maxDepth else @@DEFAULT_DEPTH) ->

      if typeof(arg) is 'function'
        if typeof(done) is 'number'
          _depth = done

        done = arg
        arg = {}

      if is-type \Array arg
        @debug-resource.Log "Listing from array: #{arg.length} entries"
        # Debug.Depth!

      @_HandleArrayArg arg, (constraints, _done) ~>
        done = (err, data) ->
          Debug.UnDepth!
          _done err, data

        @debug-resource.Log "List #{JSON.stringify constraints}"
        Debug.Depth!

        @_table.Select '*', (constraints || {}), {}, (err, blobs) ~>
          | err?  => done err?
          | _     =>
            async.map blobs, (blob, done) ~>
              @debug-resource.Log "Listed {id: #{blob.id}}"
              @resource._Deserialize blob, done, _depth
            , done

      , done

    # Delete given records from DB
    @_DeleteUnwrapped = (arg, done) ->

      if is-type \Array arg
        @debug-resource.Warn "Deleting from array: #{arg.length} entries"

      @_HandleArrayArg arg, (constraints, done) ~>
        @debug-resource.Warn "Deleting #{JSON.stringify constraints}"
        @resource._FetchUnwrapped constraints, (err, instance) ~>
          | err?  => done err
          | _     => instance._DeleteUnwrapped done

      , done

  #
  # Private
  # Init process
  #

    # Prepare the core of the Resource
    @_PrepareResource = (_config, _routes, _name, _parent = null) ->
      @debug-res.Log 'Preparing resource'

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

    # Initialisation
    @Init = (@config = @config, extendArgs) ->
      if @INITED
        return @

      super ...

      if @_routes?
        @routes = new @_routes(@, @config)

      @

  ResourceServer._PrepareResource(config, routes, name)
