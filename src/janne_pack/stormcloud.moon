bzutils = require("bzutils")

utils = bzutils.utils
component = bzutils.component

bz_handle = bzutils.bz_handle

import namespace, isIn, assignObject, proxyCall, isNullPos, local2Global, global2Local from utils
import UnitComponent, ComponentConfig, componentManager from component

import ObjectTracker, Handle from bz_handle



class Stormcloud extends UnitComponent
  new: (handle) =>
    super(handle)
    @bolts = {}
    @timer = 0.025
    @acc = 0
    @inAir = false
    @delay = @getHandle()\getInt("SprayBuildingClass", "triggerDelay")

  update: (dtime) =>
    s_pos = @getHandle()\getPosition()
    for i, v in pairs(@bolts)
      v.life -= dtime
      if v.life <= 0
        RemoveObject(i)
        @bolts[i] = nil

    @acc += dtime
    
    if @acc >= @delay
      @timer -= dtime
      if(@timer <= 0)
        p = GetCircularPos(s_pos,math.random(75) + 10, math.random(math.pi*2))
        p.y = s_pos.y
        bolt = BuildObject("boltmine", 0,p)
        SetPosition(bolt, p)
        @bolts[bolt] = {life: 0.01}
        @timer = 0.025

  unitWasRemoved: () =>
    for i, v in pairs(@bolts)
      RemoveObject(i)


ComponentConfig(Stormcloud,{
  odfs: {"splintb2"}
})

return Stormcloud

