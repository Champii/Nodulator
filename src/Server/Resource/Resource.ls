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
        debug-resource.Log "Saving  #{JSON.stringify serie}"

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
      (arg, args, config, done, _depth = @config?.maxDepth) ->

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

  #
  # Private
  # Init process
  #

    # Initialisation
    # @Init = (@config = @config, extendArgs) ->
    #   if @INITED
    #     return @
    #
    #   super ...
    #
    #   if @_routes?
    #     @routes = new @_routes(@, @config)
    #
    #   @

  ResourceServer.DB = DB
  ResourceServer._PrepareResource(config, routes, name)
