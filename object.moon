utils = require("utils")
coreM = require("core")
Rx = require("rx")
runtime = require("runtime")

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


class Handle
  new: (handle) =>
    @handle = handle

  getHandle: () =>
    @handle

  removeObject: () =>
    RemoveObject(@getHandle!)

  cloak: () =>
    Cloak(@getHandle!)
  
  decloak: () =>
    Decloak(@getHandle!)
  
  setCloaked: () =>
    SetCloaked(@getHandle!)
  
  setDecloaked: () =>
    SetDecloaked(@getHandle!)
  
  isCloaked: () =>
    return IsCloaked(@getHandle!)
  
  enableCloaking: (enable) =>
    EnableCloaking(@getHandle!,enable)
  
  getOdf: () =>
    return GetOdf(@getHandle!)
  
  hide: () =>
    Hide(@getHandle!)
  
  unHide: () =>
    UnHide(@getHandle!)
  
  getCargo: () =>
    return GetCargo(@getHandle!)
  
  formation: (other) =>
    Formation(@getHandle!,other)
  
  isOdf: (...) =>
    return IsOdf(@getHandle!, ...)
  
  getBase: () =>
    return GetBase(@getHandle!)
  
  getLabel: () =>
    return GetLabel(@getHandle!)
  
  setLabel: (label) =>
    SetLabel(@getHandle!, label)
  
  getClassSig: () =>
    return GetClassSig(@getHandle!)
  
  getClassLabel: () =>
    return GetClassLabel(@getHandle!)
  
  getClassId: () =>
    return GetClassId(@getHandle!)
  
  getNation: () =>
    return GetNation(@getHandle!)
  
  isValid: () =>
    return IsValid(@getHandle!)
  
  isAlive: () =>
    return IsAlive(@getHandle!)
  
  isAliveAndPilot: () =>
    return IsAliveAndPilot(@getHandle!)
  
  isCraf: () =>
    return IsCraft(@getHandle!)
  
  isBuilding: () =>
    return IsBuilding(@getHandle!)
  
  isPlayer: (team) =>
    return self.handle == GetPlayerHandle(team)
  
  isPerson: () =>
    return IsPerson(@getHandle!)
  
  isDamaged: (threshold) =>
    return IsDamaged(@getHandle!, threshold)
  
  getTeamNum: () =>
    return GetTeamNum(@getHandle!)
  
  getTeam: () =>
    return @getTeamNum!
  
  setTeamNum: (...) =>
    SetTeamNum(@getHandle!, ...)
  
  setTeam: (...) =>
    @setTeamNum(...)
  
  getPerceivedTeam: () =>
    return GetPerceivedTeam(@getHandle!)
  
  setPerceivedTeam: (...) =>
    SetPerceivedTeam(@getHandle!, ...)
  
  setTarget: (...) =>
    SetTarget(@getHandle!, ...)
  
  getTarget: () =>
    return GetTarget(@getHandle!)
  
  setOwner: (...) =>
    SetOwner(@getHandle!, ...)
  
  getOwner: () =>
    return GetOwner(@getHandle!)
  
  setPilotClass: (...) =>
    SetPilotClass(@getHandle!, ...)
  
  getPilotClass: () =>
    return GetPilotClass(@getHandle!)
  
  setPosition: (...) =>
    SetPosition(@getHandle!, ...)
  
  getPosition: () =>
    return GetPosition(@getHandle!)
  
  getFront: () =>
    return GetFront(@getHandle!)
  
  setTransform: (...) =>
    SetTransform(@getHandle!,...)
  
  getTransform: () =>
    return GetTransform(@getHandle!)
  
  getVelocity: () =>
    return GetVelocity(@getHandle!)
  
  setVelocity: (...) =>
    SetVelocity(@getHandle!, ...)
  
  getOmega: () =>
    return GetOmega(@getHandle!)
  
  SetOmega: (...) =>
    SetOmega(@getHandle!, ...)
  
  getWhoShotMe: (...) =>
    return GetWhoShotMe(@getHandle!, ...)
  
  getLastEnemyShot: () =>
    return GetLastEnemyShot(@getHandle!)
  
  getLastFriendShot: () =>
    return GetLastFriendShot(@getHandle!)
  
  isAlly: (...) =>
    return IsAlly(@getHandle!, ...)
  
  isEnemy: (other) =>
    return not (@isAlly(other) or (@getTeamNum! == GetTeamNum(other)) or (GetTeamNum(other) == 0) ) 
  
  setObjectiveOn: () =>
    SetObjectiveOn(@getHandle!)
  
  setObjectiveOff: () =>
    SetObjectiveOff(@getHandle!)
  
  setObjectiveName: (...) =>
    SetObjectiveName(@getHandle!, ...)
  
  getObjectiveName: () =>
    return GetObjectiveName(@getHandle!)
  
  copyObject: (odf) =>
    odf = odf or @getOdf!
    return copyObject(self.handle,odf)
  
  getDistance: (...) =>
    return GetDistance(@getHandle!, ...)
  
  isWithin: (...) =>
    return IsWithin(@getHandle!, ...)
  
  getNearestObject: () =>
    return GetNearestObject(@getHandle!)
  
  getNearestVehicle: () =>
    return GetNearestVehicle(@getHandle!)
  
  getNearestBuilding: () =>
    return GetNearestBuilding(@getHandle!)
  
  getNearestEnemy: () =>
    return GetNearestEnemy(@getHandle!)
  
  getNearestFriend: () =>
    return GetNearestFriend(@getHandle!)
  
  countUnitsNearObject: (...) =>
    return CountUnitsNearObject(@getHandle!, ...)
  
  isDeployed: () =>
    return IsDeployed(@getHandle!)
  
  deploy: () =>
    Deploy(@getHandle!)
  
  isSelected: () =>
    return IsSelected(@getHandle!)
  
  isCritical: () =>
    return IsCritical(@getHandle!)
  
  setCritical: (...) =>
    SetCritical(@getHandle!, ...)
  
  setWeaponMask: (...) =>
    SetWeaponMask(@getHandle!, ...)
  
  giveWeapon: (...) =>
    GiveWeapon(@getHandle!, ...)
  
  getWeaponClass: (...) =>
    return GetWeaponClass(@getHandle!, ...)
  
  fireAt: (...) =>
    FireAt(@getHandle!, ...)
  
  damage: (...) =>
    Damage(@getHandle!, ...)
  
  canCommand: () =>
    return CanCommand(@getHandle!)
  
  canBuild: () =>
    return CanBuild(@getHandle!)
  
  isBusy: () =>
    return IsBusy(@getHandle!)
  
  getCurrentCommand: () =>
    return GetCurrentCommand(@getHandle!)
  
  getCurrentWho: () =>
    return GetCurrentWho(@getHandle!)
  
  getIndependence: () =>
    return GetIndependence(@getHandle!)
  
  setIndependence: (...) =>
    SetIndependence(@getHandle!, ...)
  
  setCommand: (...) =>
    SetCommand(@getHandle!, ...)
  
  attack: (...) =>
    Attack(@getHandle!, ...)
  
  goto: (...) =>
    Goto(@getHandle!, ...)
  
  mine: (...) =>
    Mine(@getHandle!, ...)
  
  follow: (...) =>
    Follow(@getHandle!, ...)
  
  defend: (...) =>
    Defend(@getHandle!, ...)
  
  defend2: (...) =>
    Defend2(@getHandle!, ...)
  
  stop: (...) =>
    Stop(@getHandle!, ...)
  
  patrol: (...) =>
    Patrol(@getHandle!, ...)
  
  retreat: (...) =>
    Retreat(@getHandle!, ...)
  
  getIn: (...) =>
    GetIn(@getHandle!, ...)
  
  pickup: (...) =>
    Pickup(@getHandle!, ...)
  
  dropoff: (...) =>
    Dropoff(@getHandle!, ...)
  
  build: (...) =>
    Build(@getHandle!, ...)
  
  buildAt: (...) =>
    BuildAt(@getHandle!, ...)
  
  hasCargo: () =>
    return HasCargo(@getHandle!)
  
  getTug: () =>
    return GetTug(@getHandle!)
  
  ejectPilot: () =>
    EjectPilot(@getHandle!)
  
  hopOut: () =>
    HopOut(@getHandle!)
  
  killPilot: () =>
    KillPilot(@getHandle!)
  
  removePilot: () =>
    RemovePilot(@getHandle!)
  
  hoppedOutOf: () =>
    HoppedOutOf(@getHandle!)
  
  getHealth: () =>
    return GetHealth(@getHandle!)
  
  getCurHealth: () =>
    return GetCurHealth(@getHandle!)
  
  getMaxHealth: () =>
    return GetMaxHealth(@getHandle!)
  
  setCurHealth: (...) =>
    SetCurHealth(@getHandle!, ...)
  
  setMaxHealth: (...) =>
    SetMaxHealth(@getHandle!, ...)
  
  addHealth: (...) =>
    AddHealth(@getHandle!, ...)
  
  getAmmo: () =>
    return GetAmmo(@getHandle!)
  
  getCurAmmo: () =>
    return GetCurAmmo(@getHandle!)
  
  getMaxAmmo: () =>
    return GetMaxAmmo(@getHandle!)
  
  setCurAmmo: (...) =>
    SetCurAmmo(@getHandle!, ...)
  
  setMaxAmmo: (...) =>
    SetMaxAmmo(@getHandle!, ...)
  
  addAmmo: (...) =>
    AddAmmo(@getHandle!)
  
  _setLocal: (...) =>
    SetLocal(@getHandle!, ...)
  
  isLocal: () =>
    return IsLocal(@getHandle!)
  
  isRemote: () =>
    return IsRemote(@getHandle!)
  
  isUnique: () =>
    return @isLocal! and (@isRemote!)
  
  setHealth: (fraction) =>
    @setCurHealth(@getMaxHealth! * fraction)
  
  setAmmo: (fraction) =>
    @setCurAmmo(@getMaxAmmo! * fraction)
  
  getCommand: () =>
    return AiCommand[@getCurrentCommand!]
  
  getOdfFile: () =>
    file = @odfFile
    if (not file)
      file = OdfFile(@getOdf!)
      @odfFile = file

    return file
  
  getProperty: (section, var, ...) =>
    return @getOdfFile!\getProperty(section, var, ...)

  getFloat: (section, var, ...) =>
    return @getOdfFile!\getFloat(section, var, ...)
  
  getBool: (section, var, ...) =>
    return @getOdfFile!\getBool(section, var, ...) 
  
  getInt: (section, var, ...) =>
    return @getOdfFile!\getInt(section, var, ...)
  
  getTable: (...) =>
    return @getOdfFile!\getTable(...)
  
  getVector: (...) =>
    return @getOdfFile!\getVector(...)


class BzObject
  new: (handle) =>
    @h = Handle(handle)
    @track = {
      command: "getCurrentCommand",
      who: "getCurrentWho",
      ammo: "getAmmo",
      health: "getHealth",
      position: "getPosition"
    }
    @lvars = {i, @handle![v](@handle!) for i,v in pairs(@track)}
    @subjects = {i, Subject.create() for i,v in pairs(@track)}
  

  update: () =>
    for i,v in pairs(@track)
      c = @lvars[i]
      @lvars[i] = @handle![v](@handle!) or c
      if(@lvars[i] ~= c)
        @subjects[i]\onNext(@lvars[i],c)

  handle: () =>
    return @h
  
  onChange: (name) =>
    return @subjects[name]

  doTrack: (name,func) =>
    @track[name] = @track[name] or func
    @lvars[name] = @handle![func](@handle!)
    @subjects[name] = @subjects[name] or Subject.create()
    return @subjects[name]

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