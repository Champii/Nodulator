module.exports =

# Here are defined functions that check if the client is authenticated
# before he can access the aimed resource

  class Authentication
    @user: (done) ->
      (req, res, next) =>
        return done req, res, next if not req.params.id?
        return res.status(403).send() if !(req.user?) or req.user.id isnt parseInt(req.params.id, 10)

        done req, res, next

    @safeAccess: (done) ->
      (req, res, next) ->
        return error res, 403, "not authenticated" if not req.auth? and req.method in ["POST", "PUT", "PATCH", "DELETE"]

        done req, res, next

    @auth: (done) ->
      (req, res, next) ->
        return res.status(403).send() if !(req.user?)

        done req, res, next
