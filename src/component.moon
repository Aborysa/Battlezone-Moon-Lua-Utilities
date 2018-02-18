-- Component life cycle:
-- constructed/init - called on init
-- postInit - called after init/constructor and load
-- unitDidSpawn - called when/if the unit spawns
-- unitWasRemoved - called when the unit is removed
-- componentWillUnmount - called when the component is removed
-- unitWillTransfere - called when the component is about to be removed due to the unit having switched machine
-- unitDidTransfere - called after postInit when a component has been attached to a handle due to switching machine
-- update - runs ~every update


--UnitBehaviour:-- Component life cycle:
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
net = require("net")
rx = require("rx")

import Observable, Subject, ReplaySubject, AsyncSubject  from rx
import Module, applyMeta, getMeta, proxyCall, protectedCall, namespace, instanceof, isIn, assignObject, getFullName, Store from utils
import Handle from bz_handle
import SharedStore, BroadcastSocket from net

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
  new: (handle, props) =>
    @store = Store()
    @handle = Handle(handle)

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



-- unit component with auto sync
class SyncedUnitComponent extends UnitComponent
  new: (handle, props) =>
    super(handle, props)
    @props = props
    @localStore = Store()
    @remote = props.remote
    @storeSub = ReplaySubject.create(1)

  postInit: () =>
    print("Req socket")
    if @props.requestSocket
      @props.requestSocket(nil)\subscribe((socket) ->
        print("Got socket")
        @socket = socket
        @remoteStore = SharedStore(@localStore\getState(), socket)
        @remoteStore\onKeyUpdate()\subscribe((k,v) -> 
          print("SyncedUnitComponent update", k, v)
        )
        @storeSub\onNext(@remoteStore)
        --@storeSub\onCompleted()
      )
    else
      @storeSub\onNext(@localStore)
      --@storeSub\onCompleted()

  setState: (state) =>
    if @remoteStore
      @remoteStore\assign(state)
    else
      @localStore\assign(state)

  getStore: () =>
    @storeSub
    --return @remoteStore or @localStore
  
  state: () =>
    @remoteStore\getState()


  componentWillUnmount: () =>
    @storeSub\onCompleted()
    if @socket
      @socket\close()
    

  save: () =>
    return @state()
  
  load: (state) =>
    @localStore = Store(state)

class ComponentManager extends Module
  new: (parent, serviceManager) =>
    super(parent, serviceManager)
    @classes = {}
    --@objbyclass = {}
    @objbyhandle = {}
    @remoteHandles = {}
    @waitToAdd = {}
    @serviceManager = serviceManager
    serviceManager\getService("bzutils.net")\subscribe( (net) -> 
      @net = net
    )
  
  start: (...) =>
    super\start(...)
    for v in AllObjects()
      proxyCall(@addHandle(v),"postInit")
  
  _regHandle: (handle) =>
    @waitToAdd[handle] = nil
    objs = @addHandle(handle)
    proxyCall(objs, "postInit")
    proxyCall(objs,"unitDidSpawn")

  update: (...) =>
    super\update(...)
    for i,v in pairs(@waitToAdd)
      @_regHandle(i)


    for i,v in pairs(@objbyhandle)
      --if(not @remoteHandles[i])
      if IsValid(i) and IsNetGame()
        -- objects locality has changed
        if (not @remoteHandles[i]) ~= (not IsRemote(i))
          @remoteHandles[i] = IsRemote(i) or nil
          proxyCall(v, "unitWillTransfere")
          @objbyhandle[i] = {}
          for obj in *v
            m = getMeta(obj)
            cname = getFullName(m.parent)
            if ObjCfg(m.parent).remoteCls
              cls = @classes[cname]
              inst = @createInstance(i,cls)
              protectedCall(inst, "load", protectedCall(obj, "save"))
              protectedCall(obj, "componentWillUnmount")
              protectedCall(inst, "postInit")
              protectedCall(inst, "unitDidTransfere")
              
            else
              table.insert(@objbyhandle, obj)

      v = @objbyhandle[i]
      
      proxyCall(v,"update",...)


  addObject: (handle,...) =>
    super\addObject(handle)
    @_regHandle(handle)

  createObject: (handle,...) =>
    print("create object")
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
    props = {
      serviceManager: @serviceManager,
      remote: IsNetGame() and IsRemote(handle)
    }
    socketCount = 0
        
    if (IsNetGame() and IsRemote(handle))
      @remoteHandles[handle] = true
      if (c.remoteCls)
        props.requestSocket = () ->
          socketCount += 1
          return @net\onNetworkReady()\flatMap(() -> 
            return @net\getRemoteSocket("OBJ",handle,getFullName(cls), socketCount)
          )

        instance = c.remoteCls(handle, props)
      else
        --a bit hacky
        instance = {}
    else
      if (IsNetGame() and c.remoteCls)
        props.requestSocket = (type) ->
          socketCount += 1
          return @net\onNetworkReady()\map(() ->
            return @net\openSocket(0, type,"OBJ",handle,getFullName(cls), socketCount)
          )
      instance = cls(handle, props)
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


return {
  :ComponentManager,
  :UnitComponent,
  :ComponentConfig,
  :SyncedUnitComponent
}