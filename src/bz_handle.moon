
utils = require("utils")
rx = require("rx")

import OdfFile from utils
import Subject, AsyncSubject from rx


copyObject = (handle, odf, team, location, keepWeapons=false, kill=false, fraction=true) ->
  loc = location != nil and location or GetTransform(handle)
  odf = odf != nil and odf or GetOdf(handle)
  team = team != nil and team or GetTeamNum(handle)
  
  nObject = BuildObject(odf,team,loc)
  if(location == nil)
    SetTransform(nObject, loc)
  
  if(IsAliveAndPilot(handle)) then
    SetPilotClass(nObject, GetPilotClass(handle))
  elseif((not IsAlive(handle)) and kill) then
    RemovePilot(nObject, handle)


  SetCurHealth(nObject, fraction and GetCurHealth(handle) or GetHealth(handle) * GetMaxHealth(nObject))
  SetCurAmmo(nObject, fraction and GetCurAmmo(handle) or GetAmmo(handle) * GetMaxAmmo(nObject))
  SetVelocity(nObject, GetVelocity(handle))
  SetOmega(nObject, GetOmega(handle))
  if IsDeployed(handle)
    Deploy(nObject)
  
  SetIndependence(nObject, GetIndependence(handle))
  if keepWeapons
    for i, v in ipairs({
      GetWeaponClass(handle,0),
      GetWeaponClass(handle,1),
      GetWeaponClass(handle,2),
      GetWeaponClass(handle,3),
      GetWeaponClass(handle,4),
    }) do
      GiveWeapon(nObject,v,i-1)
  SetOwner(nObject, GetOwner(handle))

  return nObject



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
  
  setOmega: (...) =>
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
    return copyObject(@getHandle!,odf)
  
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


class ObjectTracker
  new: (handle) =>
    @h = Handle(handle)
    @track = {
      command: "getCurrentCommand",
      who: "getCurrentWho",
      ammo: "getAmmo",
      health: "getHealth",
      position: "getPosition"
    }
    @destroySubject = AsyncSubject.create()
    @lvars = {i, @handle![v](@handle!) for i,v in pairs(@track)}
    @subjects = {i, Subject.create() for i,v in pairs(@track)}
    @onChange("health")\subscribe(@\_checkHp)
    @dead = false

  update: () =>
    for i,v in pairs(@track)
      c = @lvars[i]
      @lvars[i] = @handle![v](@handle!)
      if(@lvars[i] ~= c)
        @subjects[i]\onNext(@lvars[i],c)

  _checkHp: (new, old) =>
    if not @dead and (new <= 0 and old > 0)
      @dead = true
      @destroySubject\onNext()
      @destroySubject\onCompleted()

  handle: () =>
    return @h
  
  onChange: (name) =>
    return @subjects[name]

  onDestroy: () =>
    return @destroySubject

  doTrack: (name,func) =>
    @track[name] = @track[name] or func
    @lvars[name] = @handle![func](@handle!)
    @subjects[name] = @subjects[name] or Subject.create()
    return @subjects[name]



return {
  :Handle,
  :ObjectTracker,
  :copyObject
}