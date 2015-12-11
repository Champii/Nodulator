require! {
  underscore: _
  q
  async
  browserify
  livescript
  fs
  path
  \browserify-livescript
}

module.exports = (N) ->

  assets = []

  parseRec = (dirs, rec = false) ->
    for dir in dirs when dir?

      if dir[dir.length - 1] isnt '/'
        dir += '/'

      entries = fs.readdirSync dir

      files = _(entries).filter (entry) ~>
        fs.statSync(dir + entry).isFile() and (entry.match(/\.ls$/g) or entry.match(/\.js$/g))

      if rec
        folders = _(entries).filter (entry) ~>
          fs.statSync(dir + entry).isDirectory() and not entry.match(/^\./g)
        folders = _(folders).map (folder) ~>
          dir + folder

        parseRec folders, true

      files = _(files).map (file) ~>
        if file.match(/\.ls$/g)
          dir + file
        else if file.match(/\.js$/g) or file.match(/\.css$/g)
          dir + file

      assets := assets.concat files

  parseRec [
    path.resolve __dirname, 'assets'
    path.resolve '.'
    ]

  b = browserify!

  b.transform browserify-livescript

  b.add assets

  N.Route._InitServer!
  N.app.get \/ (req, res) ->
    b.bundle (err, assets) ->
      return res.status 500 .send err if err

      # assets = '<script>' + assets + '</script>'
      assets = '<html><head></head><body><script>' + assets + '</script></body></html>'

      res.status 200 .send assets.toString!

  class View

    @_type = 'View'

    (@resource) ->
      @resource.AttachRoute N.Route.Collection


  N.Render = ->

  View.DOM = {}
  N.View = View

  # files =
  #   * \index.ls
  #
  # files |> map -> livescript.compile fs.readFileSync it


  {name: 'View'}
