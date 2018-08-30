utils = require("utils")
bz_handle = require("bz_handle")
net = require("net")
rx = require("rx")

tiny = require("tiny")
bztiny = require("bztiny")

bzcomponents = require("bzcomp")

bzserializers = require("bzserial")

Module = require("module")

import Subject from rx
import namespace from utils
import EcsWorld, requireAny, requireAll, Component from bztiny

import BzHandleComponent, BzBuildingComponent, BzVehicleComponent, BzPlayerComponent from bzcomponents

import defaultKeyFunction from bzserializers


USE_HANDLE_COMPONENT = true
USE_PLAYER_COMPONENT = true
USE_VEHICLE_COMPONENT = true


class EcsModule extends Module
  new: (...) =>
    super(...)
    @hmap = {}
    @world = EcsWorld(EcsTestSystem) --tiny.world(EcsTestSystem)

  start: () =>
    super\start()

  update: (dtime) =>
    super\update(dtime)
    @world\update(dtime)
    @world\refresh()

  addObject: (handle) =>
    super\addObject(handle)
    eid, e = @world\createEntity()
    c1 = BzHandleComponent\addEntity(e)
    c1.handle = handle
    @hmap[handle] = eid
    print(GetLabel(handle))

  deleteObject: (handle) =>
    super\deleteObject(handle)
    e = @hmap[handle]
    if e
      @world\removeEntity(e)

  getEntityId: (handle) =>
    return @hmap[handle]

  getEntity: (id) =>
    return @world\getTinyEntity(id)

  save: () =>

  load: () =>


namespace("core.ecs", EcsModule)


return {
  EntityComponentSystemModule: EcsModule
}
