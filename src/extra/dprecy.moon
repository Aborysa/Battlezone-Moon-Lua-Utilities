-- "Deployabe producer"
-- Producer that can be deployed anywhere


bzutils = require("bzutils")

utils = bzutils.utils
component = bzutils.component

bz_handle = bzutils.bz_handle

import namespace, isIn, assignObject, proxyCall, isNullPos, local2Global, global2Local from utils
import UnitComponent, ComponentConfig, componentManager from component

import ObjectTracker, Handle from bz_handle



class DeployableProducer extends UnitComponent
  new: (handle, socket) =>
    super(handle, socket)
    @deployed = @getHandle()\isDeployed()
    @geysir = nil
    @objTracker = ObjectTracker(handle)
    @cmdSub = @objTracker\onChange("command")\subscribe((command) -> 
      if AiCommand["GO_TO_GEYSER"] == command
        @geysir = BuildObject("eggeizr1", 0, @getHandle()\getTransform())
        @getHandle()\stop(0)
        @getHandle()\deploy()
    )
    @dpSub = @objTracker\doTrack("deployed", "isDeployed")\subscribe((deployed) ->
      if (not deployed) and IsValid(@geysir)
        RemoveObject(@geysir)
        @geysir = nil
        
    )

  update: (dtime) =>
    @objTracker\update(dtime)
    if IsValid(@geysir)
      pos = @getHandle()\getPosition()
      pos.y = GetTerrainHeightAndNormal(pos) - 10000
      SetPosition(@geysir, pos)

  unitWasRemoved: () =>
    if IsValid(@geysir)
      RemoveObject(@geysir)

    @dpSub\unsubscribe()
    @cmdSub\unsubscribe()


return {
  :DeployableProducer,
  defaultConf: () ->
    ComponentConfig(DeployableProducer,{
      componentName: "DeployableProducer"
    })
}

