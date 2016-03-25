require! {
  underscore: _
  q
  async
  browserify
  livescript
  fs
  path
  \browserify-livescript
  \coffeeify
  \../NModule
}

class NView extends NModule

  name: \NView

  Init: ->

    assets = []

    parseRec = (dirs, rec = false) ->
      for dir in dirs when dir?

        if dir[dir.length - 1] isnt '/'
          dir += '/'

        try
          entries = fs.readdirSync dir

          files = _(entries).filter (entry) ~>
            fs.statSync(dir + entry).isFile() and (entry.match(/\.ls$/g) or entry.match(/\.js$/g))

          if rec
            folders = _(entries).filter (entry) ~>
              fs.statSync(dir + entry).isDirectory() and not entry.match(/^\./g)
        catch e

        folders = _(folders).map (folder) ~>
          dir + folder

        parseRec folders, true

        files = _(files).map (file) ~>
          if file.match(/\.ls$/g)
            dir + file
          else if file.match(/\.js$/g) or file.match(/\.css$/g)
            dir + file

        assets := assets.concat files


    b = browserify extensions: [\.ls]

    b.transform browserify-livescript
    b.transform coffeeify


    b.add path.resolve __dirname, '../../Client/Nodulator.ls'
    b.add path.resolve __dirname, './assets/DOM.ls'
    b.add path.resolve __dirname, './assets/View.ls'
    b.add path.resolve '.'
    b.ignore 'redis'

   # class Socket extends N.Socket!

    #  OnConnect: (socket) ->

    #Socket.Init!

    socketio = '<script src="/socket.io/socket.io.js"></script>'

    N.Route._InitServer!

    if N.config?.minified
      b.bundle (err, assets) ->
        return console.log 'Err?', err if err?

        assets = "<body>#{socketio}<script>#{assets.toString!}</script>"
        N.app.get \/ (req, res) ->
          res.status 200 .send assets
    else
      N.app.get \/ (req, res) ->
        b.bundle (err, assets) ->
          console.log 'Err?', err if err?
          return if err?
          # return res.status 500 .send err if err?

          # assets = '<script>' + assets + '</script>'
          assets = "<html><head></head><body>#{socketio}<script>#{assets.toString!}</script></body></html>"

          res.status 200 .send assets

    View = ->
      @_type = 'View'

      (@resource) ->
        @resource.AttachRoute N.Route.RPC

    N.Render = ->

    View.DOM = {}
    N.View = View

    # files =
    #   * \index.ls
    #
    # files |> map -> livescript.compile fs.readFileSync it

    {name: 'View'}


module.exports = NView
