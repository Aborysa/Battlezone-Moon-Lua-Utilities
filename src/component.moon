-- Component life cycle:
-- constructed/init - called on init
-- postInit - called after init/constructor and load
-- unitDidSpawn - called when/if the unit spawns
-- unitWasRemoved - called when the unit is removed
-- componentWillUnmount - called when the component is removed
-- unitWillTransfere - called when the component is about to be removed due to the unit having switched machine
-- unitDidTransfere - called after postInit when a component has been attached to a handle due to switching machine
-- update - runs ~every update


--UnitBehaviour:

-- only runs for ai controlled craft
-- has listeners to the handle's state
-- only runs locally
-- does not sync state
-- can queue tasks

utils = require("utils")
bz_handle = require("bz_handle")
core = require("core")
net = require("net").net

rx = require("rx")

import Observable from rx
import Module, applyMeta, getMeta, proxyCall, protectedCall, namespace, instanceof, isIn, assignObject, getFullName, Store from utils
import Handle from bz_handle

ComponentConfig = (cls,cfg) ->
  applyMeta(cls,{
    Component: assignObject({
      mp_all: false,
      odfs: {},
      classLabels: {},
      componentName: "",
      remoteCls: false,
      customTest: () -> return false
    },cfg) 
  })
  return cls

ObjCfg = (cls) ->
  return getMeta(cls).Component




-- basic unit component
class UnitComponent
  new: (handle, socketSub) =>
    @store = Store()
    @handle = Handle(handle)
    if socketSub
      socketSub\subscribe((socket) -> 
        @_socket = socket
      )

  getHandle: () =>
    return @handle

  setState: (state) =>
    @store\assign(state)

  getStore: () =>
    @store

  state: () =>
    @store\getState()

  save: () =>
    return @state()
  
  load: (state) =>
    @store = Store(state)

  componentWillUnmount: () =>
    if @_socket
      @_socket\waitClose()


-- unit component with auto sync
class SyncedUnitComponent extends UnitComponent
  new: (handle, socketSub) =>
    super(handle, socketSub)
    @remote = IsRemote(handle)

    if socketSub
      socketSub\subscribe((socket) -> 
        print("Got socket!")
        @socket = socket
        socket\onReceive()\subscribe(@\receive)
        if not @remote
          print("Not Remote!")
          @getStore()\onKeyUpdate()\subscribe((key, value) ->
            print("Sending",key, value)
            socket\send("SET", key, value, 1, false, true, "Crap", {key: value})
          )
      )



  receive: (...) =>
    what, a, b = ...
    print("Recived", ...)
    if what == "SET"
      print("Setting",a,b)
      @getStore()\set(a, b)


class ComponentManager extends Module
  new: (parent) =>
    super(parent)
    @classes = {}
    --@objbyclass = {}
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
      --if(not @remoteHandles[i])
      if IsValid(i) and IsNetGame()
        -- objects locality has changed
        if (@remoteHandles[i] ~= nil) ~= (IsRemote(i) or not IsLocal(i)) 
          rem = IsRemote(i)
          @remoteHandles[i] = rem
          proxyCall(v, "unitWillTransfere")
          @objbyhandle[i] = {}
          for obj in *v
            m = getMeta(obj)
            cname = getFullName(m.parent)
            if ObjCfg(m.parent).remoteCls
              cls = rem and @classes[cname]
              inst = @createInstance(i,cls)
              protectedCall(inst, "load", protectedCall(obj, "save"))
              protectedCall(objs, "componentWillUnmount")
              protectedCall(inst, "postInit")
              protectedCall(inst, "unitDidTransfere")
              
            else
              table.insert(@objbyhandle, obj)

      v = @objbyhandle[i]
      
      proxyCall(v,"update",...)
      --else
        --print("Invalid", i)

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
    --@objbyclass[cls] = setmetatable({},{__mode: "v"})

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
    c = ObjCfg(cls)
    instance = nil
    socketSub = nil

    if (IsNetGame() and IsRemote(handle))
      @remoteHandles[handle] = true
      if (c.remoteCls)
        print("Creating remote instance")
        socketSub = net\getRemoteSocket("OBJ",handle,getFullName(cls))
        instance = c.remoteCls(handle, socketSub)
      else
        --a bit hacky
        instance = {}
    else
      if (IsNetGame() and c.remoteCls)
        socketSub = Observable.of(net\openSocket(0,"OBJ",handle,getFullName(cls)))
      instance = cls(handle, socketSub)
    --table.insert(@objbyclass[cls],instance)
    applyMeta(instance,{
      parent: cls
    })
    @objbyhandle[handle] = @objbyhandle[handle] or {}
    table.insert(@objbyhandle[handle],instance)
    return instance


  removeHandle: (handle) =>
    objs = @objbyhandle[handle]
    @objbyhandle[handle] = nil
    if objs
      proxyCall(objs,"unitWasRemoved")
      proxyCall(objs,"componentWillUnmount")
      
  save: (...) =>
    componentData = {}
    for i, v in pairs(@objbyhandle)
      --componentData[i] = componentData[i] or {}
      componentData[i] = {getFullName(obj.__class), table.pack(protectedCall(obj, "save")) for obj in *v}
      --for obj in *v
      --  componentData[i][getFullName(obj.__class)] = table.pack(obj\save()) 

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
  :ComponentConfig,
  :SyncedUnitComponent
}