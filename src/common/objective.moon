
event = require("event")
utils = require("utils")
bzserial = require("bzserial")


import EventDispatcher, Event from event
import namespace, getFullName, setMeta, getMeta from utils
import defaultKeyFunction from bzserial

class TaskState
  new: (task) =>
    @task = task
    @taskData = {}
    @taskState = {
      progress: 0, -- value between 0 and 1
      complete: false,
      success: false
    }
    @dispatcher = EventDispatcher()

  on: (event) =>
    @dispatcher\on(event)
  
  succeed: () =>
    @taskState.success = true
    @taskState.complete = true
    @dispatcher\dispatch(Event("SUCCESS", @, @task) )
  
  isCompleted: () =>
    @taskState.complete
  
  hasFailed: () =>
    @taskState.complete and not @taskState.success
  
  hasSucceeded: () =>
    @taskState.complete and @taskState.success

  fail: () =>
    @taskState.success = false
    @taskState.complete = true
    @dispatcher\dispatch(Event("FAIL", @, @task))

  progress: (v=0) =>
    if v ~= @taskState.progress
      @taskState.progress = v
      @dispatcher\dispatch(Event("PROGRESS", @, @task, v))

  reset: (v=0) =>
    @taskState.success = false
    @taskState.complete = false
    @dispatcher\dispatch(Event("RESET", @, @task))
  
  set: (state) =>
    @taskData = state
    @dispatcher\dispatch(Event("UPDATE", @, @task, state))

  get: (name) =>
    if name
      return @taskData[name]
    return @taskData

  save: () =>
    return {
      taskData: @taskData,
      taskState: @taskState
    }

  load: (data) =>
    @taskData = data.taskData
    @taskState = data.taskState

class ObjectiveTask
  -- adds a task to the given objective
  @objectives: {}
  @addTask: (objective, first=true, ...) =>
    id = getMeta(objective, "objective").id
    taskName = getFullName(@)
    task = nil
    if not @objectives[id]
      @objectives[id] = objective
      task = @()
      if first
        task\onAdd(...)
      objective._tasks[taskName] = task
    return task

  @getTask: (objective) =>
    id = getMeta(objective, "objective").id
    taskName = getFullName(@)
    if not @objectives[id]
      id = objective
    
    return (@objectives[id] or {_tasks: {}})._tasks[taskName]

  new: () =>
    @state = TaskState(@)

  -- called first time task is added to an objective
  onAdd: (...) =>

  getState: () =>
    return @state
  
  update: () =>
    return

class Objective
  new: (objectiveModule, serviceManager) =>
    @_tasks = {}
    @userData = {}
    @objectiveModule = objectiveModule
    @serviceManager = serviceManager

  init: (data) =>
    @userData = data

  -- called when the objective starts
  start: () =>

  -- return true once the objective has been completed
  isCompleted: () =>
    complete = true
    for key, task in pairs(@_tasks)
      complete = complete and task\getState()\isCompleted()

    return complete

  -- called when the objective has been completed
  completed: () =>


  update: (dtime) =>
    for key, task in pairs(@_tasks)
      if not task\getState()\isCompleted()
        task\update(dtime)

namespace("objective", Objective, ObjectiveTask, TaskState)

return {
  :Objective,
  :ObjectiveTask
}