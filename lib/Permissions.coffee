module.exports =

# In this module are defined functions that check if the client has permissions
# to access the aimed ressource

  class Permissions
    @ownedBy: (done) ->
      (req, res, next) ->
        if req['resource']? and req[req['resource']]?
            obj = req[req['resource']]
            return res.status(403).send() if obj.user != req.user.id

        done req, res, next

    @objectBased: (obj) ->
      (done) ->
        (req, res, next) ->
          for key, val of obj
            return res.status(403).send() if not req.user[key]? or req.user[key] isnt val

          done req, res, next
