

utils = require("utils")
core = require("core")


import Module, proxyCall, protectedCall, getFullName from utils




-- Routine life cycle:
-- constructed/init - called on init
-- routineWasCreated - called when the routine is created with args passed to createRoutine
-- routineWasDestroyed - called when the routine is destroyed by clearRoutine
-- postInit - called after init/constructor and load
-- update - runs ~every update


--UnitBehaviour:

class RuntimeController extends Module
  new: (...) =>
    super(...)
    @intervals = {}
    @nextIntervalId = 1
    @nextRoutineId = 1
    @routines = {}
    @classes = {}

  setInterval: (func, delay, count=-1) =>
    id = @nextIntervalId
    @nextIntervalId += 1
    @intervals[id] = {
      f: func,
      delay: delay,
      count: -1,
      time: 0
    }
    return id
    
  setTimeout: (func, delay) => 
    @setInterval(func, delay, 1)

  clearInterval: (id) =>
    @intervals[id] = nil

  createRoutine: (cls, ...) =>
    if type(cls) == "string"
      cls = @classes[cls]
      
    
    if cls == nil or @classes[getFullName(cls)] == nil
      error(("%s has not been registered via 'useClass'")\format(getFullName(cls)))
    
    id = @nextRoutineId
    @nextRoutineId += 1
    print("routine", cls)
    inst = cls((...) -> @clearRoutine(id, ...))
    @routines[id] = inst
    protectedCall(inst, "routineWasCreated", ...)
    protectedCall(inst, "postInit")

    return id, inst


  useClass: (cls) =>
    @classes[getFullName(cls)] = cls

  getRoutine: (id) => 
    return @routines[id]


  clearRoutine: (id, ...) =>
    inst = @routines[id]
    if inst
      @routines[id] = nil
      protectedCall(inst, "routineWasDestroyed", ...)
      
  update: (dtime) =>
    for i, v in pairs(@intervals) do
      v.time = v.time + dtime
      if v.time >= v.delay
        v.time -= v.delay
        v.func()
        v.count -= 1
        if v.count == 0
          @clearInterval(i)

    proxyCall(@routines,"update", dtime)
    
  save: (...) =>
    routineData = {}
    for i, v in pairs(@routines)
      routineData[i] = {
        rdata: table.pack(protectedCall(v, "save")),
        clsName: getFullName(obj.__class)
      }

    return {
      mdata: super\save(...),
      nextId: @nextRoutineId,
      :routineData
    }

  load: (...) =>
    data = ...
    super\load(data.mdata)
    @nextRoutineId = data.nextId
    for rid, routine in pairs(data.routineData)
      cls = @classes[routine.clsName]
      inst = cls((...) -> @clearRoutine(rid, ...))
      protectedCall(inst,"load",unpack(routine.rdata))
      protectedCall(inst,"postInit")



runtimeController = core\useModule(RuntimeController)

return {
  :runtimeController
}