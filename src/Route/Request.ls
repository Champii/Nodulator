require! \prelude-ls : {is-type, map}

errors =
  not_found: 404
  forbidden: 403
  'Error on Delete': 500

class Request

  instance: null
  sent: false

  ([@req, @res, @next]) ->
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

    status = errors[it.status] || 500

    @res.status(status).send it
    @sent = true

  SetInstance: ->
    if it.then?
      it.fail ~> @SendError it
      it.then ~>
        @req._instance = it
        @instance = it
        @next()
    else
      @req._instance = it
      @instance = it
      @next()

  _Parse: ->
    import @req
    @instance = @_instance if @_instance?

Request.errors = errors
module.exports = Request
