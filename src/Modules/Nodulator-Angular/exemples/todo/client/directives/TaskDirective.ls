class TaskDirective extends N.Directive 'task', 'taskService'

  err: ''
  newTask: ''

  Done: (task) ->
    task.isDone = true
    @taskService.Update task

  New: ->
    @taskService.Add {name: @newTask}, (@err, task) ~>
      @newTask = ''

  Delete: (id) ->
    @taskService.Delete id

TaskDirective.Init()
