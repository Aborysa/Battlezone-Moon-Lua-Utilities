utils = require("utils")
bz_handle = require("bz_handle")
net = require("net")
rx = require("rx")

tiny = require("tiny")
bztiny = require("bztiny")

bzcomponents = require("bzcomp")
bzsystems = require("bzsystems")

Module = require("module")

event = require("event")

import Subject from rx
import namespace, OdfFile, getMeta, getFullName from utils
import EcsWorld, requireAny, requireAll, Component, getComponentOdfs from bztiny
import BzNetworkSystem, BzPlayerSystem, BzPositionSystem from bzsystems



import BzHandleComponent, 
  BzBuildingComponent, 
  BzVehicleComponent, 
  BzPlayerComponent, 
  BzPersonComponent,
  BzRecyclerComponent,
  BzFactoryComponent,
  BzConstructorComponent,
  BzArmoryComponent,
  BzHowitzerComponent,
  BzWalkerComponent,
  BzConstructorComponent,
  BzWingmanComponent,
  BzGuntowerComponent,
  BzScavengerComponent,
  BzTugComponent,
  BzMinelayerComponent,
  BzTurretComponent 
  BzHangarComponent,
  BzSupplydepotComponent,
  BzSiloComponent,
  BzCommtowerComponent,
  BzPortalComponent,
  BzPowerplantComponent,
  BzSignComponent,
  BzArtifactComponent,
  BzStructureComponent,
  BzAnimstructureComponent,
  BzBarracksComponent, 
  PositionComponent,
  BzLocalComponent,
  BzRemoteComponent from bzcomponents


import EventDispatcher, Event from event

USE_HANDLE_COMPONENT = true
USE_PLAYER_COMPONENT = true
USE_VEHICLE_COMPONENT = true

classname_components = {
  "recycler": BzRecyclerComponent,
  "factory": BzFactoryComponent,
  "armory": BzArmoryComponent,
  "wingman": BzWingmanComponent,
  "constructionrig": BzConstructorComponent,
  "howitzer": BzHowitzerComponent,
  "scavenger": BzScavengerComponent,
  "tug": BzTugComponent,
  "turret": BzGuntowerComponent,
  "walker": BzWalkerComponent,
  "turrettank": BzTurretComponent,
  "minelayer": BzMinelayerComponent,
  "repairdepot": BzHangarComponent,
  "supplydepot": BzSupplydepotComponent,
  "silo": BzSiloComponent,
  "commtower": BzCommtowerComponent,
  "portal": BzPortalComponent,
  "powerplant": BzPowerplantComponent,
  "sign": BzSignComponent,
  "artifact": BzArtifactComponent,
  "i76building": BzStructureComponent,
  "i76building2": BzStructureComponent,
  "animbuilding": BzAnimstructureComponent
}

misc_components = {
  [BzBuildingComponent]: IsBuilding,
  [BzVehicleComponent]: IsCraft,
  [BzPersonComponent]: IsPerson
}


class EcsModule extends Module
  new: (...) =>
    super(...)
    @hmap = {}
    @world = EcsWorld()
    @handlesToProcess = {}
    @dispatcher = EventDispatcher()
  
    
    @addSystem(BzPositionSystem()\createSystem())
    @addSystem(BzPlayerSystem()\createSystem())
    --todo: network system is broken
    --if IsNetGame()
    --  @world\addSystem(BzNetworkSystem()\createSystem())


    
  getDispatcher: () =>
    @dispatcher

  start: () =>
    super\start()
    for i in AllObjects()
      @_regHandle(i)

  _setMiscComponents: (entity, handle) =>
    className = GetClassLabel(handle)
    classComponent = classname_components[className]
    
    if classComponent
      classComponent\addEntity(entity)
    
    for miscComponent, filter in pairs(misc_components)
      if filter(handle)
        miscComponent\addEntity(entity)

  _loadComponentsFromOdf: (entity, handle) =>
    odf = GetOdf(handle)
    file = OdfFile(odf)
    for component, _ in pairs(getComponentOdfs())
      cMeta = getMeta(component, "ecs.fromfile")
      header = cMeta.header
      use = file\getBool(header, header, false)
      if use
        comp = component\addEntity(entity)
        file\getFields(header, cMeta.fields, comp)


  addSystem: (system) =>
    @world\addSystem(system)
    system.getEntityByHandle = @\getEntityByHandle
    system.registerHandle = @\_regHandle
    @dispatcher\dispatch(Event("ECS_ADD_SYSTEM",@,nil, system))

  -- moves components from old handle to new handle
  -- should be called after new handle is created
  replaceHandle: (old, new) =>
      
    @handlesToProcess[new] = nil
    eid = @getEntityId(old)
    entity = @getEntity(eid)
    handleComponent = BzHandleComponent\getComponent(entity)
    handleComponent.handle = new
    
    -- was not called early, remove entity that was created
    if @getEntityId(new) ~= nil
      neid = @getEntityId(new)
      @world\removeEntity(neid)

      
    @hmap[old] = nil
    @hmap[new] = eid

    RemoveObject(old)

  _regHandle: (handle) =>
    @handlesToProcess[handle] = nil
    if not @hmap[handle]
      eid, e = @world\createEntity()
      c1 = BzHandleComponent\addEntity(e)
      c1.handle = handle

      c2 = PositionComponent\addEntity(e)
      c2.position = GetPosition(handle)

      if IsNetGame()
        if IsLocal(handle)
          BzLocalComponent\addEntity(e)
        if IsRemote(handle)
          BzRemoteComponent\addEntity(e)

      else
        BzLocalComponent\addEntity(e)

      @hmap[handle] = eid
      @_loadComponentsFromOdf(e, handle)
      @_setMiscComponents(e, handle)
      @dispatcher\dispatch(Event("ECS_REG_HANDLE",@,nil,handle, eid, e))

  _unregHandle: (handle) =>
    eid = @hmap[handle]
    if eid
      entity = @world\getTinyEntity(eid)
      if entity
        handleComponent = BzHandleComponent\getComponent(entity)
        if handleComponent and handleComponent.removeOnDeath then
          @world\removeEntity(eid)
        @dispatcher\dispatch(Event("ECS_UNREG_HANDLE",@,nil,handle, eid, entity))
      @hmap[handle] = nil

  getWorld: () =>
    @world
  
  update: (dtime) =>
    super\update(dtime)
    for i, v in pairs(@handlesToProcess)
      @_regHandle(i)
      @handlesToProcess[i] = nil
  
    @world\update(dtime)
    @world\refresh()

  createObject: (handle) =>
    @handlesToProcess[handle] = true

  addObject: (handle) =>
    super\addObject(handle)
    @handlesToProcess[handle] = true

  deleteObject: (handle) =>
    super\deleteObject(handle)
    @_unregHandle(handle)

  getEntityByHandle: (handle) =>
    id = @getEntityId(handle)
    if id ~= nil
      return @getEntity(id)

  getEntityId: (handle) =>
    return @hmap[handle]

  getEntity: (id) =>
    return @world\getTinyEntity(id)

  save: () =>
    data = {
      ecs: @world\save(),
      handles: @hmap
    }
    
    return data

  load: (data) =>
    @world\load(data.ecs)
    @hmap = data.handles


namespace("core.ecs", EcsModule)


return {
  EntityComponentSystemModule: EcsModule
}
