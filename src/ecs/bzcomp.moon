
bztiny = require("bztiny")
utils = require("utils")


import Component from bztiny
import namespace from utils

class BzHandleComponent extends Component
  new: () =>
    -- wether or not the entity should be removed once the handle is no longer valid
    @removeOnDeath = true


-- misc components
class BzBuildingComponent extends Component
class BzVehicleComponent extends Component
class BzPersonComponent extends Component
class BzPlayerComponent extends Component
class BzLocalComponent extends Component
class BzRemoteComponent extends Component
-- class name components
-- vehicles
class BzRecyclerComponent extends Component
class BzFactoryComponent extends Component
class BzArmoryComponent extends Component
class BzHowitzerComponent extends Component
class BzWalkerComponent extends Component
class BzConstructorComponent extends Component
class BzWingmanComponent extends Component
class BzGuntowerComponent extends Component
class BzTurretComponent extends Component
class BzScavengerComponent extends Component
class BzTugComponent extends Component
class BzMinelayerComponent extends Component



-- buildings
class BzHangarComponent extends Component
class BzSupplydepotComponent extends Component
class BzSiloComponent extends Component
class BzCommtowerComponent extends Component
class BzPortalComponent extends Component
class BzPowerplantComponent extends Component
class BzSignComponent extends Component
class BzArtifactComponent extends Component
class BzStructureComponent extends Component
class BzAnimstructureComponent extends Component

-- misc objects/powerups
class BzCamerapodComponent extends Component




-- other
class PositionComponent extends Component
  new: () =>
    @position = SetVector(0, 0, 0)


class ParticleEmitterComponent extends Component
  new: () =>
    @explodf = nil
    @nextExpl = 0
    @minInterval = 0
    @maxInterval = 0
    @_init = false
  
  init: (min, max = min) =>
    @minInterval = min
    @maxInterval = max
    @_init = true
    @nextInterval()

  nextInterval: () =>
    diff = @maxInterval - @minInterval
    @nextExpl = @minInterval + diff * math.random()
      


namespace("ecs.component", 
  BzHandleComponent, 
  BzBuildingComponent, 
  BzVehicleComponent, 
  BzPlayerComponent,
  BzPersonComponent,
  BzRecyclerComponent,
  BzFactoryComponent,
  BzArmoryComponent,
  BzHowitzerComponent,
  BzWalkerComponent,
  BzConstructorComponent,
  BzWingmanComponent,
  BzGuntowerComponent,
  BzTurretComponent,
  BzScavengerComponent,
  BzTugComponent,
  BzMinelayerComponent,
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
  ParticleEmitterComponent,
  BzLocalComponent,
  BzRemoteComponent
)


return {
  :BzHandleComponent,
  :BzBuildingComponent,
  :BzVehicleComponent,
  :BzPlayerComponent,
  :BzPersonComponent,
  :IsPerson,
  :BzRecyclerComponent,
  :BzFactoryComponent,
  :BzArmoryComponent,
  :BzHowitzerComponent,
  :BzWalkerComponent,
  :BzConstructorComponent,
  :BzWingmanComponent,
  :BzGuntowerComponent,
  :BzTurretComponent
  :BzScavengerComponent,
  :BzTugComponent,
  :BzMinelayerComponent,
  :BzHangarComponent,
  :BzSupplydepotComponent,
  :BzSiloComponent,
  :BzCommtowerComponent,
  :BzPortalComponent,
  :BzPowerplantComponent,
  :BzSignComponent,
  :BzArtifactComponent,
  :BzStructureComponent,
  :BzAnimstructureComponent,
  :BzBarracksComponent,
  :ParticleEmitterComponent,
  :BzLocalComponent,
  :BzRemoteComponent,
  :PositionComponent
}
