

utils = require("utils")
core = require("core")


import Module, proxyCall, protectedCall, getFullName, applyMeta, getMeta from utils



-- Routine life cycle:
-- constructed/init - called on init
-- routineWasCreated - called when the routine is created with args passed to createRoutine
-- routineWasDestroyed - called when the routine is destroyed by clearRoutine
-- postInit - called after init/constructor and load
-- update - runs ~every update


--UnitBehaviour:

setRuntimeState = (inst, state) ->
  applyMeta(inst, {
    runtime: {
      state: state
    }
  })

getRuntimeState = (inst, state) ->
  getMeta(inst).runtime.state


class RuntimeController extends Module
  new: (...) =>
    super(...)
    @intervals = {}
    @nextIntervalId = 1
    @nextRoutineId = 1
    @routines = {}
    @classes = {}
    -- routines that should be removed
    @garbage = {}

  setInterval: (func, delay, count=-1) =>
    id = @nextIntervalId
    @nextIntervalId += 1
    @intervals[id] = {
      func: func,
      delay: delay,
      count: -1,
      time: 0
    }
    setRuntimeState(@intervals[id], 1)
    return id
    
  setTimeout: (func, delay) => 
    @setInterval(func, delay, 1)

  clearInterval: (id) =>
    if getRuntimeState(@intervals[id]) ~= 0
      setRuntimeState(@intervals[id], 0)
      table.insert(@garbage,{
        t: @intervals,
        k: id
      }) 

  createRoutine: (cls, ...) =>
    print("Creating routine", getFullName(cls))
    if type(cls) == "string"
      cls = @classes[cls]
      
    
    if cls == nil or @classes[getFullName(cls)] == nil
      error(("%s has not been registered via 'useClass'")\format(getFullName(cls)))
    
    id = @nextRoutineId
    @nextRoutineId += 1
    inst = cls((...) -> @clearRoutine(id, ...))
    setRuntimeState(inst, 1)
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
    if inst and getRuntimeState(inst) ~= 0
      setRuntimeState(inst, 0)
      protectedCall(inst, "routineWasDestroyed", ...)
      table.insert(@garbage,{
        t: @routines,
        k: id
      })

  update: (dtime) =>
    for i, v in ipairs(@garbage)
      v.t[v.k] = nil

    @garbage = {}

    for i, v in pairs(@intervals)
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
        clsName: getFullName(v.__class)
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
      @routines[rid] = inst


runtimeController = core\useModule(RuntimeController)

return {
  :runtimeController
}