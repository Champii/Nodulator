_ = require \underscore
Route = require \./Route

class MultiRoute extends Route

  Config: ->
    super()
    console.log 'MAIS LOL YA QQN ????'
    @All    \/:id* ~>
      console.log 'All'
      it.SetInstance @resource.Fetch +it.params.id

    @Get           ~>
      console.log 'Get'
      @resource.List it.query

    @Post          ~>
      console.log 'post'
      @resource.Create it.body

    @Get    \/:id  ~>
      console.log 'Get2'
      it.instance
    @Put    \/:id  ~>
      console.log 'Put'
      it.instance.ExtendSafe it.body
      it.instance.Save!
    @Delete \/:id  ~>
      console.log 'Delete'
      it.instance.Delete!

module.extends = MultiRoute
