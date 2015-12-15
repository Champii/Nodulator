rest = require 'rest'
mime = require('rest/interceptor/mime');

Client = rest.wrap(mime)

class RESTClient

  (@name) ->

  Fetch: (blob, done) ->
    Client method: \POST path: \/api/1/ + @name + '/fetch', headers: {'Content-Type': 'application/json'}, entity: blob
      .then ~> done null it.entity
      .catch done

  Create: (blob, done) ->
    Client method: \POST path: \/api/1/ + @name + '/create', headers: {'Content-Type': 'application/json'}, entity: blob
      .then ~> done null it.entity
      .catch done
  List: (blob, done) ->
    Client method: \POST path: \/api/1/ + @name + '/list', headers: {'Content-Type': 'application/json'}, entity: blob
      .then ~> done null it.entity
      .catch done
  Delete: (id, blob, done) ->
    Client method: \POST path: \/api/1/ + @name + '/delete/' + id, headers: {'Content-Type': 'application/json'}, entity: blob
      .then ~> done null it.entity
      .catch done

  Set: (id, blob, done) ->
    Client method: \POST path: \/api/1/ + @name + '/set/' + id, headers: {'Content-Type': 'application/json'}, entity: blob
      .then ~> done null it.entity
      .catch done

N.Client = RESTClient
