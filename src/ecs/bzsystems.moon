bztiny = require("bztiny")

bzcomponents = require("bzcomponents")

import BzPlayerComponent, BzHandleComponent from bzcomponents



class BzPlayerSystem
  process: (entity) =>
    handle = BzHandleComponent\getEntity(entity)
    playerComponent = BzPlayerComponent\getEntity(entity)
    isPlayer = GetPlayerHandle() == handle
    if isPlayer and not playerComponent
      BzPlayerComponent\addEntity(entity)
    elseif not isPlayer and playerComponent
      BzPlayerComponent\removeEntity(entity)



return {
  :BzPlayerSystem
}
