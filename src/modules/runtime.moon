

utils = require("utils")
rx = require("rx")
Module = require("module")

import proxyCall, protectedCall, getFullName, applyMeta, getMeta from utils

import Subject from rx


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
  new: (parent, serviceManager) =>
    super(parent, serviceManager)
    @serviceManager = serviceManager
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
      count: count,
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
    props = {
      terminate: (...) -> @clearRoutine(id, ...),
      serviceManager: @serviceManager
    }
    inst = cls(props)
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
        v.func(v.time)
        v.time -= v.delay
        v.count -= 1
        if v.count == 0
          @clearInterval(i)
    for i, v in pairs(@routines)
      if getRuntimeState(v) ~= 0
        protectedCall(v, "update", dtime)

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
      props = {
        terminate: (...) -> @clearRoutine(rid, ...),
        serviceManager: @serviceManager
      }
      inst = cls(props)
      protectedCall(inst,"load",unpack(routine.rdata))
      protectedCall(inst,"postInit")
      @routines[rid] = inst


class Timer
  new: (time, loop=0, serviceManager) =>
    @life = loop + 1
    @time = time
    @acc = 0
    @tleft = time
    @running = false
    @alarmSubject = Subject.create()
    @r_id = -1
    serviceManager\getService("bzutils.runtime")\subscribe((runtimeController) -> 
      @runtimeController = runtimeController
    )

  _round: () =>
    @reset()
    @life -= 1
    if(@life <= 0)
      @running = false

    @alarmSubject\onNext(@,math.abs(@life),@acc)

  update: (dtime) =>
    if(@running)
      @acc += dtime
      @tleft -= dtime
      if(@tleft <= 0)
        @_round()

  start: () =>
    if @r_id < 0
      if(@life > 0)
        @running = true
        @r_id = @runtimeController\setInterval(@\update, @time/4)

  setLife: (life) =>
    @life = life

  reset: () =>
    @tleft = @time

  stop: () =>
    if @running
      @runtimeController\clearInterval(@r_id)
      @r_id = -1
    @pause()
    @reset()

  pause: () =>
    @running = false

  onAlarm: () =>
    return @alarmSubject

  save: () =>
    return @tleft, @acc, @running, @life, @r_id

  load: (...) =>
    @tleft, @acc, @running, @life = ...
    if @running
      @start()


return {
  :RuntimeController,
  :getRuntimeState,
  :Timer
}
