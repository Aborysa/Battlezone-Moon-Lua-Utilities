
tiny = require("tiny")

bztiny = require("bztiny")

bzcomponents = require("bzcomp")

import BzPlayerComponent, BzHandleComponent, PositionComponent, ParticleEmitterComponent from bzcomponents



class System
  createSystem: (f) =>
    return f(@)

class BzPlayerSystem extends System
  filter: () => bztiny.requireAll(BzHandleComponent)
  process: (entity) =>
    handle = BzHandleComponent\getEntity(entity)
    playerComponent = BzPlayerComponent\getEntity(entity)
    isPlayer = GetPlayerHandle() == handle
    if isPlayer and not playerComponent
      BzPlayerComponent\addEntity(entity)
    elseif not isPlayer and playerComponent
      BzPlayerComponent\removeEntity(entity)

  createSystem: () =>
    super(tiny.processingSystem)

class PositionSystem extends System
  filter: () => bztiny.requireAll(BzHandleComponent, PositionComponent)
  process: (entity) =>
    positionComponent = PositionComponent\getComponent(entity)
    handleComponent = HandleComponent\getComponent(entity)
    pos = GetPosition(handleComponent.handle)
    positionComponent.position = pos

  createSystem: () =>
    super(tiny.processingSystem)


class ParticleSystem extends System
  filter: () => bztiny.requireAll(ParticleEmitterComponent, PositionComponent)
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
  :PositionComponent,
  :ParticleComponent
}
