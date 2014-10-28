module.exports =

# In this module are defined functions that check if the client has permissions
# to access the aimed ressource

  class Permissions
    @ownedBy: (done) ->
      (req, res, next) ->
    # FIXME : implement by pulling the user row
    #                      check that the user own the object
    # user = User.Fetch req.id
    # return res.status(403).send() if obj.user != user
      done req, res, next

    @objectBased: (obj) ->
      (done) ->
        (req, res, next) ->
          for key, val of obj
            return res.status(403).send() if not req.user[key]? or req.user[key] isnt val

          done req, res, next
