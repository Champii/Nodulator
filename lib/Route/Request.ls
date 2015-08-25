require! \prelude-ls : {is-type, map}

errors =
  not_found: 404
  'Error on Delete': 500

class Request

  instance: null
  sent: false

  ([@req, @res, @next]:args) ->
    # console.log @req

    @_Parse!

  Send: !->
    return if @sent

    if is-type 'Array' it
      it := map (-> if it.ToJSON? => it.ToJSON! else it), it

    if it.ToJSON? => @res.status(200).send it.ToJSON!
    else          => @res.status(200).send it

    @sent = true

  SendError: ->
    return if @sent

    console.log 'SendError', it
    @res.status(errors[it.status]).send it
    @sent = true

  SetInstance: ->
    switch true
      | it.then? =>
        it.fail ~>
          @SendError it
        it.then ~>
          @req._instance = it
          @instance = it
          @next()
      | _        =>
        @req._instance = it
        @instance = it
        @next()

  _Parse: ->
    # console.log 'PARSE', @
    import @req
    @instance = @_instance if @_instance?
    # console.log 'Parsed instance', @instance

Request.errors = errors
module.exports = Request
