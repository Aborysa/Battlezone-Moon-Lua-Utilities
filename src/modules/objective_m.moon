Module = require("module")
event = require("event")
utils = require("utils")

objective = require("objective")

import Event, EventDispatcher from event

import Objective from objective

import simpleIdGeneratorFactory, getFullName, getClass, namespace, setMeta from utils




class ObjectiveModule extends Module
  new: (parent, serviceManager) =>
    super(parent, serviceManager)
    @serviceManager = serviceManager
    @dispatcher = EventDispatcher()
    @idGenerator = simpleIdGeneratorFactory()
    @objectives = {}
    @activeObjectives = {}
    @objectiveArgs = {}
  

  createObjective: (cls, id=@idGenerator()) =>
    obj = cls(@, serviceManager)
    @objectives[id] = obj
    setMeta(obj, "objective", {
      :id
    })
    return id, obj

  _completeObjective: (id) =>
    obj = @getObjective(id)
    obj\completed()
    @activeObjectives[id] = nil


  startObjective: (id) =>
    obj = @getObjective(id)
    obj\start()
    @activeObjectives[id] = obj


  getObjective: (id) =>
    return @objectives[id]

  update: (dtime) =>
    for id, obj in pairs(@activeObjectives)
      obj\update(dtime)

    for id, obj in pairs(@activeObjectives)
      if obj\isCompleted()
        @_completeObjective(id)


  save: () =>
    active = {}
    objectives = {}
    for id, obj in pairs(@activeObjectives)
      table.insert(active, id)
    
    for id, obj in pairs(@objectives)
      objectives[id] = {
        cls: getFullName(obj.__class),
        tasks: {},
        userData: obj.userData
      }
      for clsname, task in pairs(obj._tasks)
        objectives[id].tasks[clsname] = task\getState()\save()

    return {
      nextId: @idGenerator()-1,
      :active,
      :objectives
    }

  load: (data) =>
    @idGenerator = simpleIdGeneratorFactory(data.nextId)
    for id, objective in pairs(data.objectives)
      objcls = getClass(objective.cls)
      _, obj = @createObjective(objcls, id)
      for taskname, task in pairs(objective.tasks)
        taskcls = getClass(taskname)
        taskcls\addTask(obj, false)\getState()\load(task)
      obj\init(objective.userData)

    for _, id in ipairs(data.active)
      @activeObjectives[id] = @getObjective(id)

namespace("core.objective", ObjectiveModule)

return {
  :ObjectiveModule
}