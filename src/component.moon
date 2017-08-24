-- Component life cycle:
-- constructed/init - called on init
-- postInit - called after init/constructor and load
-- unitDidSpawn - called when/if the component spawns
-- unitWasRemoved - called when the component is removed, runs on all machines in mp
-- unitWillTransfere
-- unitDidTransfere - might not use this 
-- update - runs on local machine in mp
-- remoteUpdate - runs on remote machines in mp


--UnitBehaviour:

-- only runs for ai controlled craft
-- has listeners to the handle's state
-- only runs locally
-- does not sync state
-- can queue tasks

utils = require("utils")
bz_handle = require("bz_handle")
core = require("core")


import Module, applyMeta, getMeta, proxyCall, protectedCall, namespace, instanceof, isIn, assignObject, getFullName from utils
import Handle from bz_handle

ComponentConfig = (cls,cfg) ->
  applyMeta(cls,{
    Component: assignObject({
      mp_all: false,
      odfs: {},
      classLabels: {},
      componentName: "",
      customTest: () -> return false
    },cfg) 
  })
  return cls

ObjCfg = (cls) ->
  return getMeta(cls).Component





class UnitComponent
  new: (handle) =>
    @_state = {}
    @handle = Handle(handle)


  getHandle: () =>
    return @handle

  setState: (state) =>
    @_state = assignObject(@_state,state)
    -- MP syncing here
  state: () =>
    @_state

  save: () =>
    return @_state
  
  load: (state) =>
    @_state = state




class ComponentManager extends Module
  new: (parent) =>
    super(parent)
    @classes = {}
    @objbyclass = {}
    @objbyhandle = {}
    @remoteHandles = {}
    @waitToAdd = {}
  
  start: (...) =>
    super\start(...)
    for v in AllObjects()
      proxyCall(@addHandle(v),"postInit")
  
  _regHandle: (handle) =>
    @waitToAdd[handle] = nil
    objs = @addHandle(handle)
    proxyCall(objs, "postInit")
    if not (IsNetGame() and IsRemote(handle))
      proxyCall(objs,"unitDidSpawn")

  update: (...) =>
    super\update(...)
    for i,v in pairs(@waitToAdd)
      @_regHandle(i)

    for i,v in pairs(@objbyhandle)
      if(not @remoteHandles[i])
        proxyCall(v,"update",...)
      else
        proxyCall(v,"remoteUpdate",...)
    
  addObject: (handle,...) =>
    super\addObject(handle)
    @_regHandle(handle)

  createObject: (handle,...) =>
    super\createObject(handle,...)
    @waitToAdd[handle] = true
    --proxyCall(@addHandle(...),"init")

  deleteObject: (...) =>
    super\deleteObject(...)
    @removeHandle(...)


  getComponents: (handle) =>
    return @objbyhandle[handle] or {}

  getComponent: (handle,cls) =>
    for i,v in pairs(@getComponents(handle))
      if(instanceof(v,cls))
        return v

  useClass: (cls) =>
    @classes[getFullName(cls)] = cls
    @objbyclass[cls] = setmetatable({},{__mode: "v"})

  addHandle: (handle) =>
    if @objbyhandle[handle]
      return {}
    ret = {}
    h = Handle(handle)
    odf = h\getOdf()
    classLabel = h\getClassLabel!
    componentNames = h\getTable("GameObjectClass","componentName")
    for i, v in pairs(@classes)
      c = ObjCfg(v)
      use = isIn(classLabel,c.classLabels) or
        isIn(c.componentName,componentNames) or
        isIn(odf,c.odfs) or
        c.customTest(handle)
      
      if use
        table.insert(ret,@createInstance(handle,v))

    return ret

  createInstance: (handle,cls) =>
    instance = cls(handle)
    table.insert(@objbyclass[cls],instance)
    @objbyhandle[handle] = @objbyhandle[handle] or {}
    table.insert(@objbyhandle[handle],instance)
    if (IsNetGame() and IsRemote(handle))
      @remoteHandles[handle] = true
    return instance

    
  removeHandle: (handle) =>
    objs = @objbyhandle[handle]
    @objbyhandle[handle] = nil
    if objs
      proxyCall(objs,"unitWasRemoved")
      
  
  save: (...) =>
    componentData = {}
    for i, v in pairs(@objbyhandle)
      componentData[i] = componentData[i] or {}
      for obj in *v
        componentData[i][getFullName(obj.__class)] = table.pack(obj\save()) 

    return {
      mdata: super\save(...)
      :componentData
    }

  load: (...) =>
    data = ...
    super\load(data.mdata)
    print(...)
    for i, v in pairs(data.componentData)
      for clsName, data in pairs(v)
        cls = @classes[clsName]
        inst = @createInstance(i, cls)
        protectedCall(inst,"load",unpack(data))
        protectedCall(inst,"postInit")
        
namespace("component",ComponentManager, UnitComponent)
componentManager = core\useModule(ComponentManager)


return {
  :ComponentManager,
  :UnitComponent,
  :componentManager,
  :ComponentConfig
}