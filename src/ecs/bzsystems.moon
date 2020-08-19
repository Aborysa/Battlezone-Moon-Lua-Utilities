
tiny = require("tiny")

bztiny = require("bztiny")

bzcomponents = require("bzcomp")

import BzPlayerComponent, BzHandleComponent, PositionComponent, BzBuildingComponent, ParticleEmitterComponent, BzLocalComponent, BzRemoteComponent from bzcomponents



class System
  createSystem: (f) =>
    return f(@)

  @processingSystem: (...) =>
    inst = @(...)
    inst.__type = "processingSystem"
    return tiny.processingSystem(inst)

  @sortedSystem: (...) =>
    inst = @(...)
    inst.__type = "sortedSystem"
    return tiny.sortedSystem(inst)

  @sortedProcessingSystem: (...) =>
    inst = @(...)
    inst.__type = "sortedProcessingSystem"
    return tiny.sortedProcessingSystem(inst)

  @system: (...) =>
    inst = @(...)
    inst.__type = "system"
    return tiny.system(inst)

class BzPlayerSystem extends System
  filter: bztiny.requireAll(BzHandleComponent)
  process: (entity) =>
    handle = BzHandleComponent\getComponent(entity).handle
    playerComponent = BzPlayerComponent\getComponent(entity)
    isPlayer = GetPlayerHandle() == handle
    if isPlayer and not playerComponent
      print("update")
      BzPlayerComponent\addEntity(entity)
      @.bzworld\updateTinyEntity(entity)
    elseif not isPlayer and playerComponent
      print("update")
      BzPlayerComponent\removeEntity(entity)
      @.bzworld\updateTinyEntity(entity)
    
  createSystem: () =>
    super(tiny.processingSystem)

class BzPositionSystem extends System
  filter: bztiny.requireAll(BzHandleComponent, PositionComponent, bztiny.rejectAny(BzBuildingComponent)) 
  process: (entity) =>
    positionComponent = PositionComponent\getComponent(entity)
    handleComponent = BzHandleComponent\getComponent(entity)
    pos = GetPosition(handleComponent.handle)
    positionComponent.position = pos

  createSystem: () =>
    super(tiny.processingSystem)

class BzNetworkSystem extends System
  filter: bztiny.requireAll(BzHandleComponent)
  interval: 2
  preProcess: () =>
    @entitiesToUpdate = {}
  process: (entity) =>
    handleComponent = BzHandleComponent\getComponent(entity)
    handle = handleComponent.handle
    if IsLocal(handle) and BzLocalComponent\getComponent(entity) == nil
      BzLocalComponent\addEntity(entity)
      @entitiesToUpdate[entity] = true
    elseif BzLocalComponent\getComponent(entity) ~= nil
      BzLocalComponent\removeEntity(entity)
      @entitiesToUpdate[entity] = true
    
    if IsRemote(handle) and BzRemoteComponent\getComponent(entity) == nil
      BzRemoteComponent\addEntity(entity)
      @entitiesToUpdate[entity] = true
    elseif BzRemoteComponent\getComponent(entity) ~= nil
      BzRemoteComponent\removeEntity(entity)
      @entitiesToUpdate[entity] = true

  postProcess: () =>
    for i, v in ipairs(@entitiesToUpdate)
      @.bzworld\updateTinyEntity(i)

  createSystem: () =>
    super(tiny.processingSystem)


class ParticleSystem extends System
  filter: bztiny.requireAll(ParticleEmitterComponent, PositionComponent)
  process: (entity, dtime) =>
    particleComponent = ParticleEmitterComponent\getComponent(entity)
    particleComponent.nextExpl -= dtime
    if particleComponent.nextExpl <= 0
      particleComponent\nextInterval()
      odf = particleComponent.nextExpl
      positionComponent = PositionComponent\getComponent(entity)
      if IsBzr()
        MakeExplosion(odf, positionComponent.position)
  
  createSystem: () =>
    super(tiny.processingSystem)

return {
  :BzPlayerSystem,
  :BzPositionSystem,
  :BzNetworkSystem,
  :System
}
