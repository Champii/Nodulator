require! {
  async
  underscore: _
  validator: Validator
  \./Helpers/Debug
  # \../../ : N
}

validationError = (field, value, message) ->
  field: field
  value: value
  message: "The '#field' field #{if value? => "with value '#value'"} #message"

typeCheck =
  bool: (value) -> typeof(value) isnt 'string' and '' + value is 'true' or '' + value is 'false'
  int: is-type \Number
  float: is-type \Number
  string: is-type \String
  date: Validator.isDate
  email: Validator.isEmail
  array: (value) -> Array.isArray value
  arrayOf: (type) -> (value) ~> not _(map (@[type]), value).contains (item) -> item is false

class SchemaProperty

  name: null
  default: null
  unique: false
  optional: true
  internal: false
  unique: false
  type: null
  validation: null

  (@name, @type, @optional) ->
    throw new Error 'SchemaProperty must have a name' if not @name?

    if is-type \Array @type
      @validation = typeCheck.arrayOf @type.0
    else
      @validation = typeCheck[@type]

  Default: (@default) ->  @
  Unique: (@unique = true) -> @
  Optional: (@optional = true) -> @
  Required: (required = true) -> @optional = !required; @
  Virtual: (@virtual = null) -> @
  Internal: (@internal = true) -> @
  Unique: (@unique = true) -> @

class Schema

  mode: null

  (@name, @mode = 'free') ->
    @properties = []
    @assocs = []
    @habtm = []
    @debug = new Debug "N::Resource::#{@name}::Schema", Debug.colors.cyan

  Populate: (instance, blob) ->

    res = obj-to-pairs blob |> filter (.0.0 isnt \_) |> pairs-to-obj
    instance <<< res

    @properties
      |> each (-> instance[it.name] =
        | blob[it.name]?  => that
        | it.default?     => switch
          | is-type \Function it.default  => it.default!
          | _                             => it.default
        | _               => void)

    @assocs |> each -> instance[it.name] = that if blob[it.name]?

    @properties
      |> filter (.virtual?)
      |> each ~>
        try
          result = it.virtual.call instance, instance, (val) ~>
            instance[it.name] = val

          if result?
            instance[it.name] = result
        catch e
          instance[it.name] = undefined

    instance

  Filter: (instance) ->

    res = {}

    if @mode is \strict
      res.id = instance.id
      @properties
        |> filter (-> not it.virtual?)
        |> each -> res[it.name] = instance[it.name]
    else
      each (~>
        if it[0] isnt \_ and typeof! instance[it] isnt 'Function' and
             it not in map (.name), @assocs and
             not _(@properties).findWhere(name: it)?.virtual? and
             (typeof! instance[it]) isnt 'Object' and
             (typeof! instance[it]) isnt 'Array'

           res[it] = instance[it]), keys instance

    res

  RemoveInternals: (blob) ->
    @properties
      |> filter (.internal)
      |> each -> delete blob[it.name]
    blob

  Field: (name, type) ->
    return that if _(@properties).findWhere name: name

    @properties.push new SchemaProperty name, type, @mode is 'free'
    @properties[*-1]

  # Check for schema validity
  Validate: (blob, done) ->

    errors = []

    @properties
      |> each ~>
        errors := errors.concat @_CheckPresence blob, it
        errors := errors.concat @_CheckValid blob, it

    errors = errors.concat @_CheckNotInSchema blob
    @_CheckUnique blob, @Resource, (err, results) ->
      if err?
        errors := errors.concat results
      done(if errors.length => {errors} else null)


  GetVirtuals: (instance, blob) ->
    res = {}
    (@properties or [])
      |> filter (.virtual?)
      |> each (-> res[it.name] = it.virtual.call instance, blob, ->)

    res

  _CheckPresence: (blob, property) ->
    if !property.optional and not property.default? and not blob[property.name]? and not property.virtual?
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

  _CheckUnique: (blob, Resource, done) ->
    res = []
    async.eachSeries filter((.unique), @properties), (property, done) ->
      Resource.Fetch (property.name): blob[property.name]
        .Then ->
          res.push validationError property.name, blob[property.name], ' must be unique'
          done {err: 'not unique'}
        .Catch -> done!
    , (err, results) -> done err, res

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
        if _depth < 0
          return done()

        if !isArray
          if not typeCheck.int blob[description.localKey]
            return done new Error 'Model association needs integer as id and key'
        else
          if not typeCheck.array blob[description.localKey]
            return done new Error 'Model association needs array of integer as ids and localKeys'

        description.type.Fetch blob[description.localKey], done, _depth

    else if description.distantKey?
      foreign = description.distantKey
      keyType = \distant
      get = (blob, done, _depth) ->
        if _depth < 0 or not blob.id?
          return done()

        if !isArray
          description.type.Fetch {"#{description.distantKey}": blob.id} , done, _depth
        else
          description.type.List {"#{description.distantKey}": blob.id}, done, _depth

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

    console.log 'FetchAssocs', blob, @name, _depth
    # @debug.Log "Fetching #{@assocs.length} assocs with Depth #{_depth}"
    async.eachSeries @assocs, (resource, _done) ~>
      done = (err, data)->
        _done err, data

      # @debug.Log "Assoc: Fetching #{resource.name}"
      resource.Get blob, (err, instance) ->
        assocs[resource.name] = resource.default if resource.default?

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

      assoc = _(@assocs).findWhere name: capitalize through.name
      assoc.Get blob, (err, instance) ->
        return done err if err?

        done null, instance[capitalize res._type]
      , _depth + 1

    toPush  =
      keyType: 'distant'
      type: res
      name: capitalize res._type
      Get: get
    @assocs.push toPush

  HasManyThrough: (res, through) ->
    get = (blob, done, _depth) ~>
      return done! if not _depth or not blob.id?

      assoc = _(@assocs).findWhere name: capitalize through.name
      assoc.Get blob, (err, instance) ->
        return done err if err?

        res._ListUnwrapped instance[capitalize res._type], (err, instances) ->
          return done err if err?

          done null, instances
        , depth

      , _depth

    toPush  =
      keyType: 'distant'
      type: res
      name: capitalize res._type
      Get: get
    @assocs.push toPush

  HasAndBelongsToMany: (res, through) ->
    get = (blob, done, _depth) ~>
      return done! if not _depth or not blob.id?

      through._ListUnwrapped "#{@name + \Id }": blob.id, (err, instances) ~>
        return done err if err?

        async.mapSeries instances, (instance, done) ~>
          res._FetchUnwrapped instance[res._type + \Id ], done, _depth - 1
        , (err, results) ~>
          return done err if err?

          assocs =
            | results.length => results
            | _              => null

          done null, assocs

      , _depth

    toPush  =
      keyType: 'distant'
      type: res
      name: capitalize res._type
      Get: get
    @assocs.push toPush
    @habtm.push through
    # console.log @habtm

  Inherit: ->
    properties: @properties
                  |> map ->
                    sp = new SchemaProperty it.name, it.type, it.optional
                    sp <<< it
    assocs: map (-> _ {} .extend it), @assocs
    habtm: map (-> _ {} .extend it), @habtm


module.exports = Schema
