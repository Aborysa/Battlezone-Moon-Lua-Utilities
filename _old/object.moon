utils = require("utils")
coreM = require("core")
Rx = require("rx")
runtime = require("runtime")

Handle = require("handle")


import applyMeta, dropMeta, getMeta, protectedCall, proxyCall, namespace, instanceof, OdfFile, isIn, assignObject, getFullName from utils
import Subject from Rx
import Module, core from coreM
import runtimeManager from runtime



ObjectConfig = (cls,cfg) ->
  applyMeta(cls,{
    Object: assignObject({
      mp_all: false,
      odfs: {},
      classLabels: {},
      customClass: "",
      customTest: () -> return false
    },cfg) 
  })
  return cls

ObjCfg = (cls) ->
  return getMeta(cls).Object





class ObjectManager extends Module
  new: (parent) =>
    super(parent)
    @classes = {}
    @objbyclass = {}
    @objbyhandle = {}

  start: (...) =>
    super\start(...)
    for v in AllObjects()
      @addHandle(v)
    for i,v in pairs(@objbyhandle)
      proxyCall(v,"start",...)
    
  update: (...) =>
    super\update(...)
    --for i,v in pairs(@objbyhandle)
      --proxyCall(v,"update",...)

  addObject: (...) =>
    super\addObject(...)
    for i,v in pairs(@objbyhandle)
      proxyCall(v,"addObject",...)
   
  createObject: (...) =>
    super\createObject(...)
    for i,v in pairs(@objbyhandle)
      proxyCall(v,"createObject",...)
    proxyCall(@addHandle(...),"init")

  deleteObject: (...) =>
    super\deleteObject(...)
    for i,v in pairs(@objbyhandle)
      proxyCall(v,"deleteObject",...)
    @removeHandle(...)

  addPlayer: (...) =>
    super\addPlayer(...)
    for i,v in pairs(@objbyhandle)
      proxyCall(v,"addPlayer",...)

  createPlayer: (...) =>
    super\createPlayer(...)
    for i,v in pairs(@objbyhandle)
      proxyCall(v,"createPlayer",...)

  deletePlayer: (...) =>
    super\deletePlayer(...)
    for i,v in pairs(@objbyhandle)
      proxyCall(v,"deletePlayer",...)
  
  gameKey: (...) =>
    super\gameKey(...)
    for i,v in pairs(@objbyhandle)
      proxyCall(v,"gameKey",...)
  
  getInstances: (handle) =>
    return @objbyhandle[handle]

  getInstance: (handle,cls) =>
    for i,v in pairs(@getInstances(handle))
      if(instanceof(v,cls))
        return v

  useClass: (cls) =>
    @classes[getFullName(cls)] = cls
    @objbyclass[cls] = setmetatable({},{__mode: "v"})

  addHandle: (handle) =>
    if @objbyhandle[handle]
      return
    ret = {}
    h = Handle(handle)
    odf = h\getOdf()
    classLabel = h\getClassLabel!
    customClasses = h\getTable("GameObjectClass","customClass")
    for i, v in pairs(@classes)
      c = ObjCfg(v)
      use = isIn(classLabel,c.classLabels) or
        isIn(c.classLabel,customClasses) or
        isIn(odf,c.odfs) or
        c.customTest(handle)
      print(classLabel,c.classLabels[1],use)
      if use
        table.insert(ret,@createInstance(handle,v))

    return ret

  createInstance: (handle,cls) =>
    instance = cls(handle)
    table.insert(@objbyclass[cls],instance)
    @objbyhandle[handle] = @objbyhandle[handle] or {}
    table.insert(@objbyhandle[handle],instance)
    runtimeManager\addInstance(instance)
    return instance

    
  removeHandle: (handle) =>
    for i,v in pairs(@objbyhandle[handle] or {})
      id = runtimeManager\getInstanceId(v)
      runtimeManager\removeInstance(id)
    
    proxyCall(@objbyhandle[handle] or {},"delete")
    @objbyhandle[handle] = nil
      
  
  save: (...) =>
    return {
      mdata: super\save(...)
    }

  load: (...) =>
    data = ...
    super\load(data.mdata)


namespace("Object",ObjectManager)

objectManager = core\useModule(ObjectManager)


class ElevatorTest extends BzObject
  new: (handle) =>
    @floor = 0
    @dir = 0
    super(handle)
  
  init: () =>
    print("Init of TankTest")

  update: (dtime) =>
    super\update(dtime)
    h = super\handle!
    p = h\getPosition()
    p.y = GetTerrainHeightAndNormal(p)
    h\setPosition(p + SetVector(0,@floor,0))
    if(h\isWithin(GetPlayerHandle(),50))
      @floor += 10*dtime*@dir
    @floor = math.min(math.max(@floor,-10),50)
  
  gameKey: (key) =>
    if(key == "PageUp")
      @dir = 1
    if(key == "PageDown")
      @dir = -1
    if(key == "Space")
      @dir = 0



ObjectConfig(ElevatorTest,{
  classLabels: {},
  customTest: (h) -> return IsBuilding(h)
})



class WingmanTest extends BzObject
  new: (handle) =>
    super(handle)
    super\onChange("command")\subscribe((...) -> print("New command:",...))
  
  init: () =>
    print("Init of TankTest")

  update: (dtime) =>
    super\update(dtime)



ObjectConfig(WingmanTest,{
  classLabels: {},
  customTest: (h) -> return not IsBuilding(h)
})




objectManager\useClass(ElevatorTest)
objectManager\useClass(WingmanTest)


{
  :BzObject,
  :Handle,
  :ObjectManager,
  :objectManager,
  :ObjectConfig
}