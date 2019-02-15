utils = require("utils")
bz_handle = require("bz_handle")
net = require("net")
rx = require("rx")

tiny = require("tiny")
bztiny = require("bztiny")

bzcomponents = require("bzcomp")

Module = require("module")

event = require("event")

import Subject from rx
import namespace, OdfFile, getMeta, getFullName from utils
import EcsWorld, requireAny, requireAll, Component, getComponentOdfs from bztiny

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
  BzBarracksComponent from bzcomponents


import EventDispatcher, Event from event

USE_HANDLE_COMPONENT = true
USE_PLAYER_COMPONENT = true
USE_VEHICLE_COMPONENT = true

classname_components = {
  "recylcer": BzRecyclerComponent,
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
    @world = EcsWorld(EcsTestSystem) --tiny.world(EcsTestSystem)
    @handlesToProcess = {}
    @dispatcher = EventDispatcher()
  
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


  _regHandle: (handle) =>
    @handlesToProcess[handle] = nil
    if not @hmap[handle]
      eid, e = @world\createEntity()
      c1 = BzHandleComponent\addEntity(e)
      c1.handle = handle
      @hmap[handle] = eid
      @_loadComponentsFromOdf(e, handle)
      @_setMiscComponents(e, handle)
      @dispatcher\dispatch(Event("ECS_REG_HANDLE",@,nil,handle))

  _unregHandle: (handle) =>
    eid = @hmap[handle]
    if eid
      entity = @world\getTinyEntity(eid)
      if entity
        handleComponent = BzHandleComponent\getComponent(entity)
        if handleComponent and handleComponent.removeOnDeath then
          @world\removeEntity(eid)
        @dispatcher\dispatch(Event("ECS_UNREG_HANDLE",@,nil,handle))
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
    @_regHandle(handle)

  deleteObject: (handle) =>
    super\deleteObject(handle)
    @_unregHandle(handle)

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
