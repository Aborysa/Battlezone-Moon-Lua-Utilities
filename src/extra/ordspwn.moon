-- Ordnance spawner


-- "Deployabe producer"
-- Producer that can be deployed anywhere


bzutils = require("bzutils")

utils = bzutils.utils
component = bzutils.component

bz_handle = bzutils.bz_handle

import namespace, isIn, assignObject, proxyCall, isNullPos, local2Global, global2Local from utils
import UnitComponent, ComponentConfig, componentManager from component

import ObjectTracker, Handle from bz_handle



class OrdnanceSpawner extends UnitComponent
  new: (handle, props) =>
    super(handle, props)
    @objTracker = ObjectTracker(handle)
    @ammoSub = @objTracker\onChange("ammo")\subscribe((ammo) -> 
      if ammo <= 0 and @getHandle()\getMaxAmmo() > 0
        @getHandle()\removeObject()
    )
    Hide(handle)
    @initialized = false
    @movement = {
      type: "none"
    }

  enableRandomMovement: (center, minRad, maxRad) =>
    @movement = {
      type: "random",
      minRad: minRad,
      maxRad: maxRad,
      center: center
    }
 
  enableTracking: (handle) =>
    @movement = {
      type: "track",
      target: handle
    }
  setWeapon: (weapon, scount, transform, delay) =>
    @delay = delay
    @weapon = weapon
    ordName = utils.OdfFile(weapon)\getProperty("WeaponClass", "ordName")
    @ammo = 0
    if ordName
      print(ordName, utils.OdfFile(ordName)\getInt("OrdnanceClass", "ammoCost"))
      @ammo = utils.OdfFile(ordName)\getInt("OrdnanceClass", "ammoCost") * scount
    
    @transform = transform
    @getHandle()\setMaxAmmo(@ammo)
    @getHandle()\setCurAmmo(@ammo)
    if UseItem(("%s.odf")\format(@weapon)) == nil
      @getHandle()\setMaxAmmo(1)
      @getHandle()\setCurAmmo(0)
    @getHandle()\setMaxHealth(0)
    @getHandle()\giveWeapon(weapon, 0)
    @getHandle()\setWeaponMask(1)
    if @delay ~= nil and @timer == nil
      @timer = utils.Timer(delay, -1)
      @tsub = @timer\onAlarm()\subscribe(() -> 
        @getHandle()\giveWeapon(@weapon, 0)
      )
      @timer\start()
    @initialized = true
  
  setTransform: (transform) =>
    @transform = transform

  update: (dtime) =>
    @objTracker\update(dtime)
    if @timer
      @timer\update(dtime)
    if @initialized
      @getHandle()\fireAt()
      @getHandle()\setTransform(@transform)
      if @movement.type == "random"
        pos = GetPositionNear(@movement.center, @movement.minRad, @movement.maxRad)
        pos.y = @movement.center.y
        @transform.posit_x = pos.x
        @transform.posit_y = pos.y
        @transform.posit_z = pos.z
      elseif @movement.type == "track"
        if IsValid(@movement.target)
          pos = GetPosition(@movement.target)
          pos.y = pos.y + 50
          @transform.posit_x = pos.x
          @transform.posit_y = pos.y
          @transform.posit_z = pos.z
        
      
    @getHandle()\setVelocity(SetVector(0,0,0))
    @getHandle()\setOmega(SetVector(0,0,0))
    @getHandle()\setIndependence(0)
    @getHandle()\stop()

  unitWasRemoved: () =>
    @ammoSub\unsubscribe()
    if @tsub
      @tsub\unsubscribe()


OrdnanceSpawnerFactory = (serviceManager) ->
  componentManager = serviceManager\getService("bzutils.component")
  SpawnOrdnance = (odf, team, ...) ->
    obj = BuildLocal(odf, team, SetVector(0,0,0))
    comp = componentManager\getComponent(obj, OrdnanceSpawner)
    if comp
      comp\setWeapon(...)
    else
      RemoveObject(obj)
    
    return comp
  
  return SpawnOrdnance


return {
  :OrdnanceSpawner,
  :OrdnanceSpawnerFactory,
  defaultConf: () ->
    ComponentConfig(OrdnanceSpawner,{
      componentName: "OrdnanceSpawner",
      odfs: {"svtas8"}
    })
}

