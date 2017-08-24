utils = require("utils")
coreM = require("core")

import assignMeta, getMeta, protectedCall, proxyCall, namespace, instanceof from utils
import Module, core from coreM


class RunCap
  new: (instance) =>
    print("RunCap",instance)
    @handle = setmetatable({},{__mode: "v"}) 
    @handle.i = instance
    @ltime = GetSimTime()

  update: () =>
    protectedCall(@handle.i,"update",GetSimTime() - @ltime)
    @ltime = GetSimTime()
  
  getInstance: () =>
    return @handle.i

class RuntimeManager extends Module
  new: (parent) =>
    super(parent)
    @objects = {}
    @objectIndecies = setmetatable({},{__mode: "k"})
    @next_id = 1

  update: (dtime) =>
    super\update(dtime)
    SimulateTime(dtime)
    for i, v in pairs(@objects)
      if v\getInstance() == nil
        @objects[i] = nil

    proxyCall(@objects,"update")

  newId: () =>
    @next_id += 1
    return @next_id - 1
  
  addInstance: (instance) =>
    id = @newId()
    @objects[id] = RunCap(instance)
    @objectIndecies[instance] = id
    return id

  getInstanceId: (instance) =>
    return @objectIndecies[instance]

  getInstance: (id) =>
    return @objects[id]\getInstance()

  removeInstance: (id) =>
    i = @objects[id]
    @objects[id] = nil
    @objectIndecies[i] = nil
    return i



namespace("runtime",RuntimeManager)

runtimeManager = core\useModule(RuntimeManager)


{
  :RuntimeManager,
  :runtimeManager
}