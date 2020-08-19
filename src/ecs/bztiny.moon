utils = require("utils")
rx = require("rx")
tiny = require("tiny")

event = require("event")

bzserializers = require("bzserial")

import Subject from rx


import namespace, getFullName, setMeta, getMeta from utils

import Event, EventDispatcher from event
import serializeEntity, deserializeEntity from bzserializers

convertArgsToNames = (...) ->
  t = {...}
  for i=1, #t
    t[i] = (type(t[i]) == "string" or type(t[i]) == "function") and t[i] or getFullName(t[i])

  return unpack(t)

requireAll = (...) ->
  return tiny.requireAll(convertArgsToNames(...))

requireAny = (...) ->
  return tiny.requireAny(convertArgsToNames(...))

rejectAny = (...) ->
  return tiny.rejectAny(convertArgsToNames(...))

rejectAll = (...) ->
  return tiny.rejectAll(convertArgsToNames(...))


_component_odfs = setmetatable({},{})

loadFromFile = (component, header, fields={}) ->
  -- should component data be loaded from an odf file
  setMeta(component, "ecs.fromfile", {
    :header,
    :fields
  })
  _component_odfs[component] = true

getComponentOdfs = () ->
  return _component_odfs

class Component
  @entities: {}
  @dispatcher: EventDispatcher()
  @addEntity: (entity) =>
    id = getMeta(entity, "ecs").id
    if id
      @entities[id] = entity
    cm = @getName()
    if not entity[cm]
      entity[cm] = @()

    @dispatcher\dispatch(Event("ECS_COMPONENT_ADDED", @, nil, entity))
    return entity[cm]

  @removeEntity: (entity) =>
    print("removing component from entity", entity, @getName())

    @dispatcher\dispatch(Event("ECS_COMPONENT_REMOVED", @, nil, entity))
    entity[@getName()] = nil

  @getComponent: (entity) =>
    return entity[@getName()]

  @getName: () =>
    getFullName(@)

  @getEntities: () =>
    return @entities

  @getDispatcher: () =>
    return @dispatcher




class EcsWorld
  new: (...) =>
    @world = tiny.world(...)
    @world.bzworld = @
    @entities = {}
    @nextId = 1
    @TPS = 60
    @acc = 0
    @dispatcher = EventDispatcher()

  update: (dtime) =>
    @acc += dtime
    for i=1, math.floor(@acc*@TPS)
      tiny.update(@world, 1/@TPS)
      tiny.refresh(@world)
      @acc -= 1/@TPS


  createEntity: (eid) =>
    if not eid
      eid = @nextId
      @nextId+=1
    
    entity = {}
    setMeta(entity, "ecs", {
      id: eid
    })

    tiny.addEntity(@world, entity)

    @entities[eid] = entity
    @dispatcher\dispatch(Event("ECS_CREATE_ENTITY",@,nil,entity))
    return eid, entity

  updateTinyEntity: (entity) =>
    tiny.addEntity(@world, entity)

  updateEntity: (eid) =>
    -- update entity after it has changed
    @updateTinyEntity(@getTinyEntity(eid))

  removeEntity: (eid) =>
    if(@entities[eid])
      tiny.removeEntity(@world, @entities[eid])
      @dispatcher\dispatch(Event("ECS_REMOVE_ENTITY",@,nil,@entities[eid]))
      @entities[eid] = nil

  removeTinyEntity: (entity) =>
    id = @getEntityId(entity)
    @removeEntity(id)

  addSystem: (system) =>
    tiny.addSystem(@world, system)
    system.bzworld = @
    @dispatcher\dispatch(Event("ECS_ADD_SYSTEM",@,nil, system))
      
  getTinyWorld: () =>
    return @world

  getDispatcher: () =>
    @dispatcher
  --internal
  remove: (...) =>
    tiny.remove(@world, ...)

  getTinyEntity: (eid) =>
     return @entities[eid]

  getEntityId: (entity) =>
    return getMeta(entity, "ecs").id

  getEntities: () =>
    return @entities

  refresh: () =>
    tiny.refresh(@world)

  removeSystem: (system) =>
    tiny.removeSystem(@world, system)
    system.bzworld = nil
    @dispatcher\dispatch(Event("ECS_ADD_SYSTEM",@,nil, system))

  clearSystems: (...) =>
    for i = #@world.systems, 1, -1
      @removeSystem(@world.systems[i])
    tiny.clearSystems(@world, ...)
    @dispatcher\dispatch(Event("ECS_CLEAR_SYSTEMS",@,nil,...))

  clearEntities: (...) =>
    for i, v in ipairs(@world.entities)
      @removeTinyEntity(v)

    tiny.clearEntities(@world, ...)
    @dispatcher\dispatch(Event("ECS_CLEAR_ENTITIES",@,nil,...))


  getEntityCount: (...) =>
    tiny.getEntityCount(@world, ...)

  getSystemCount: (...) =>
    tiny.getSystemCount(@world, ...)

  setSystemIndex: (...) =>
    tiny.setSystemIndex(@world, ...)

  save: () =>
    data = {
      entities: {},
      _entity_count: @getEntityCount(),
      _next_id: @nextId
    }
    entities = @getEntities()
    for id, entity in pairs(entities)
      data.entities[id] = serializeEntity(entity)

    return data

  load: (data) =>
    @nextId = data._next_id
    for id, entityData in pairs(data.entities)
      eid, entity = @createEntity(id)
      deserializeEntity(entityData, entity)

namespace("ecs", EcsWorld, Component)

return {
  :EcsWorld,
  :requireAll,
  :requireAny,
  :rejectAll,
  :rejectAny,
  :Component,
  :loadFromFile,
  :getComponentOdfs
}
