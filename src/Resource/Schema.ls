require! {
  async
  underscore: _
  validator: Validator
  \../Helpers/Debug
  \../../ : N
}

global import require \prelude-ls

validationError = (field, value, message) ->
  field: field
  value: value
  message: "The '#field' field #{if value? => "with value '#value'"} #message"

typeCheck =
  bool: (value) -> typeof(value) isnt 'string' and '' + value is 'true' or '' + value is 'false'
  int: Validator.isInt
  string: (value) -> true # FIXME: call add subCheckers
  date: Validator.isDate
  email: Validator.isEmail
  array: (value) -> Array.isArray value
  arrayOf: (type) -> (value) ~> not _(map (@[type]), value).contains (item) -> item is false

class SchemaProperty

  name: null
  default: null
  unique: false
  optional: true
  type: null
  validation: null

  (@name, @type, @optional) ->
    throw new Error 'SchemaProperty must have a name' if not @name?
    # throw new Error 'SchemaProperty must have a type' if not @type?

    if is-type \Array @type
      @validation = typeCheck.arrayOf @type.0
    else
      @validation = typeCheck[@type]

  Default: (@default) ->  @
  Unique: (@unique = true) -> @
  Optional: (@optional = true) -> @
  Required: (required = true) -> @optional = !required
  Virtual: (@virtual = null) -> @

class Schema

  mode: null

  (@name, @mode = 'free') ->
    @properties = []
    @assocs = []
    @habtm = []
    @debug = new Debug "N::Resource::#{@name}::Schema", Debug.colors.cyan
    # console.log 'Schema constructor', @assocs

  Process: (blob) ->

    if @mode is \free
      blob = obj-to-pairs blob |> filter (.0.0 isnt \_) |> pairs-to-obj
    res = blob
    # else
    #   res := {}

    @properties
      |> filter (-> it.name of blob)
      |> each (-> res[it.name] =
        | blob[it.name]?  => that
        | it.default?     => that
        | _               => void)

    @assocs |> each -> res[it.name] = blob[it.name] if blob[it.name]?

    @properties
      |> filter (.virtual?)
      |> each ~>
        return if res[it.name]?
        res = it.virtual res, (val) ~>
          res[it.name] = val

        if res?
          res[it.name] = res

    res

  Filter: (instance) ->

    res = {}

    if @mode is \strict
      @properties |> filter (-> not it.virtual?) |> each -> res[it.name] = instance[it.name]
    else
      each (~> res[it] = instance[it] if it[0] isnt \_ and typeof! instance[it] isnt 'Function' and
                                         it not in keys @assocs and
                                         not _(@properties).findWhere(name: it)?.virtual? and
                                         typeof! instance[it] isnt 'Object'), keys instance
    res

    # switch
    #   | @_schema? =>  keys @_schema |> each ~>
    #     if not (it in <[_assoc _virt]>) and (it not in map (.name), @_schema._assoc) and (it not in map (.name), @_schema._virt)
    #       res[it] = @[it]
    #   | _         =>  each (~> res[it] = @[it] if it[0] isnt \_ and typeof! @[it] isnt 'Function'), keys @

  Field: (name, type) ->
    return that if _(@properties).findWhere name: name

    @properties.push new SchemaProperty name, type, @mode is 'free'
    @properties[*-1]

  # Check for schema validity
  Validate: (blob, done) ->
    delete blob._id if N.config.dbType is \Mongo

    errors = []

    @properties
      |> each ~>
        errors := errors.concat @_CheckPresence blob, it
        errors := errors.concat @_CheckValid blob, it

    errors = errors.concat @_CheckNotInSchema blob

    done(if errors.length => {errors} else null)

  GetVirtuals: (blob)-> (@properties |> filter (.virtual?) |> map (.virtual blob)) || []

  _CheckPresence: (blob, property) ->
    if !property.optional and not property.default? and not blob[property.name]?
      [validationError property.name, blob[property.name], ' was not present.']
    else
      []

  _CheckValid: (blob, property) ->
    if blob[property.name]? and not (property.validation)(blob[property.name])
      [validationError property.name,
                                 blob[property.name],
                                 ' was not a valid ' + property.type]
    else
      []
  _CheckNotInSchema: (blob) ->
    return [] if @mode is \free

    for field, value of blob when not _(@properties).findWhere name: field and field isnt \id
      validationError field, blob[field], ' is not in schema'

  PrepareRelationship: (isArray, field, description) ->
    type = null
    foreign = null
    get = (blob, done) ->
      done new Error 'No local or distant key given'

    # debug-res.Log "Preparing Relationships with #{description.type.name}"

    if description.localKey?
      keyType = \local
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
      keyType = \distant
      get = (blob, done, _depth) ->
        if not _depth or not blob.id?
          return done()

        if !isArray
          description.type._FetchUnwrapped {"#{description.distantKey}": blob.id} , done, _depth - 1
        else
          description.type._ListUnwrapped {"#{description.distantKey}": blob.id}, done, _depth - 1

    toPush  =
      keyType: keyType
      type: description.type
      name: field
      Get: get
      foreign: foreign
    toPush.default = description.default if description.default?
    @assocs.push toPush

  # Get each associated Resource
  FetchAssoc: (blob, done, _depth) ->
    assocs = {}

    @debug.Log "Fetching #{@assocs.length} assocs with Depth #{_depth}"
    # Debug.Depth!
    async.eachSeries @assocs, (resource, _done) ~>
      done = (err, data)->
        # Debug.UnDepth!
        _done err, data

      @debug.Log "Assoc: Fetching #{resource.name}"
      # Debug.Depth!
      resource.Get blob, (err, instance) ->
        assocs[resource.name] = resource.default if resource.default?

        # if err?
          # debug-resource.Error "Assoc: #{resource.name} #{JSON.stringify err}"

        if err? and resource.type is \distant => done!
        else
          assocs[resource.name] = instance if instance?
          done!
      , _depth
    , (err) ->
      return done err if err?

      done null, _.extend blob, assocs

  HasOneThrough: (res, through) ->
    get = (blob, done, _depth) ~>
      return done! if not _depth or not blob.id?

      assoc = _(@assocs).findWhere name: capitalize through.lname
      assoc.Get blob, (err, instance) ->
        return done err if err?

        done null, instance[capitalize res.lname]
      , _depth + 1

    toPush  =
      keyType: 'distant'
      type: res
      name: capitalize res.lname
      Get: get
    @assocs.push toPush

  HasManyThrough: (res, through) ->
    get = (blob, done, _depth) ~>
      return done! if not _depth or not blob.id?

      assoc = _(@assocs).findWhere name: capitalize through.lname + \s
      assoc.Get blob, (err, instance) ->
        return done err if err?

        res._ListUnwrapped instance[capitalize res.lname], (err, instances) ->
          return done err if err?

          done null, instances
        , depth - 1

      , _depth

    toPush  =
      keyType: 'distant'
      type: res
      name: capitalize res.lname + \s
      Get: get
    @assocs.push toPush

  HasAndBelongsToMany: (res, through) ->
    get = (blob, done, _depth) ~>
      return done! if not _depth or not blob.id?

      through._ListUnwrapped "#{@name + \Id }": blob.id, (err, instances) ~>
        return done err if err?

        async.mapSeries instances, (instance, done) ~>
          res._FetchUnwrapped instance[res.lname + \Id ], done, _depth - 1
        , (err, results) ~>
          return done err if err?

          # console.log results
          assocs =
            | results.length => results
            | _              => null

          done null, assocs

      , _depth

    toPush  =
      keyType: 'distant'
      type: res
      name: capitalize res.lname + \s
      Get: get
    @assocs.push toPush
    @habtm.push through
    # console.log @habtm


module.exports = Schema
