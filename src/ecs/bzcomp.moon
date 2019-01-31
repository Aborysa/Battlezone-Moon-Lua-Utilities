
bztiny = require("bztiny")
utils = require("utils")


import Component from bztiny
import namespace from utils

class BzHandleComponent extends Component
  new: () =>
    -- wether or not the entity should be removed once the handle is no longer valid
    @removeOnDeath = true

class BzBuildingComponent extends Component
class BzVehicleComponent extends Component
class BzPlayerComponent extends Component


namespace("ecs.component", BzHandleComponent, BzBuildingComponent, BzVehicleComponent, BzPlayerComponent)

return {
  :BzHandleComponent,
  :BzBuildingComponent,
  :BzVehicleComponent,
  :BzPlayerComponent
}
