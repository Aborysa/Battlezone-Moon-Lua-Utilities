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
import namespace, OdfFile, getMeta from utils
import EcsWorld, requireAny, requireAll, Component, getComponentOdfs from bztiny

import BzHandleComponent, BzBuildingComponent, BzVehicleComponent, BzPlayerComponent from bzcomponents


import EventDispatcher, Event from event

USE_HANDLE_COMPONENT = true
USE_PLAYER_COMPONENT = true
USE_VEHICLE_COMPONENT = true



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

  _loadComponentsFromOdf: (entity, handle) =>
    odf = GetOdf(handle)
    file = OdfFile(odf)
    for component, _ in pairs(getComponentOdfs())
      cMeta = getMeta(component, "ecs.fromfile")
      header = cMeta.header
      use = file\getBool(header, "use", false)
      if use
        comp = component\addEntity(entity)
        for field, t in pairs(cMeta.fields)
          v = nil
          if t == "bool"
            v = file\getBool(header, field, false)
          elseif t == "string"
            v = file\getProperty(header, field)
          elseif t == "float"
            v = file\getFloat(header, field, 0)
          elseif t == "int"
            v = file\getInt(header, field, 0)
          elseif t == "vector"
            v = file\getVector(header, field)
          elseif t == "table"
            v = file\getTable(header, field)
          elseif type(t) == "function"
            v = file\getValueAs(t, header, field)
          else
            v = file\getProperty(header, field)
          
          comp[field] = v




  _regHandle: (handle) =>
    @handlesToProcess[handle] = nil
    if not @hmap[handle]
      eid, e = @world\createEntity()
      c1 = BzHandleComponent\addEntity(e)
      c1.handle = handle
      @hmap[handle] = eid
      @_loadComponentsFromOdf(e, handle)
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
