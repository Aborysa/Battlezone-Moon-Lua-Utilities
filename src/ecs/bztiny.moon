utils = require("utils")
rx = require("rx")
tiny = require("tiny")

import Subject from rx

import namespace, getFullName, setMeta, getMeta from utils



convertArgsToNames = (...) ->
  t = {...}
  for i=1, #t
    t[i] = (type(t[i]) == "string" or typeof(t[i]) == "function") and t[i] or getFullName(t[i])

  return unpack(t)

requireAll = (...) ->
  return tiny.requireAll(convertArgsToNames(...))

requireAny = (...) ->
  return tiny.requireAny(convertArgsToNames(...))

rejectAny = (...) ->
  return tiny.rejectAny(convertArgsToNames(...))

rejectAny = (...) ->
    return tiny.rejectAll(convertArgsToNames(...))




class Component
  @entities = {}
  @addEntity: (entity) =>
    id = getMeta(entity, "ecs").id
    if id
      @entities[id] = entity
    cm = @getName()
    if not entity[cm]
      entity[cm] = @()

    return entity[cm]

  @removeEntity: (entity) =>
    entity[@getName()] = nil

  @getComponent: (entity) =>
    return entity[@getName()]

  @getName: () =>
    getFullName(@)

  @getEntities: () =>
    return @entities




class EcsWorld
  new: (...) =>
    @world = tiny.world(...)
    @entities = {}
    @nextId = 1
    @TPS = 60
    @acc = 0

  update: (dtime) =>
    @acc += dtime
    for i=1, math.floor(@acc*@TPS)
      tiny.update(@world, 1/@TPS)
      @acc -= 1/@TPS

    tiny.refresh(@world)

  createEntity: (...) =>
    eid = @nextId
    entity = {}
    setMeta(entity, "ecs", {
      id: eid
    })

    tiny.addEntity(@world, entity)

    @entities[eid] = entity
    @nextId+=1
    return eid, entity

  removeEntity: (eid) =>
    if(@entities[eid])
      print("remove",eid)
      tiny.removeEntity(@world, @entities[eid])
      @entities[eid] = nil

  addSystem: (...) =>
    tiny.addSystem(@world, ...)

  getTinyWorld: () =>
    return @world

  --internal
  remove: (...) =>
    tiny.remove(@world, ...)

  getTinyEntity: (eid) =>
     return @entities[eid]

  getEntities: () =>
    return @entities

  refresh: () =>
    tiny.refresh(@world)

  removeSystem: (...) =>
    tiny.removeSystem(@world, ...)

  clearSystems: (...) =>
    tiny.clearSystems(@world, ...)

  getEntityCount: (...) =>
    tiny.getEntityCount(@world, ...)

  getSystemCount: (...) =>
    tiny.getSystemCount(@world, ...)

  setSystemIndex: (...) =>
    tiny.setSystemIndex(@world, ...)

namespace("ecs", EcsWorld, Component)

return {
  :EcsWorld,
  :requireAll,
  :requireAny,
  :rejectAll,
  :rejectAny,
  :Component
}
