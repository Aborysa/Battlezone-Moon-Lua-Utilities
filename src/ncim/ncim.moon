
bzutils = require("bzutils")

utils = bzutils.utils
component = bzutils.component

bz_handle = bzutils.bz_handle

import namespace, isIn, assignObject, proxyCall, isNullPos, local2Global, global2Local from utils
import UnitComponent, ComponentConfig, componentManager from component

import ObjectTracker, Handle from bz_handle

Turret = nil
TurretTower = nil
ReactorHealthy = nil
ReactorDamaged = nil



class TurretTower extends UnitComponent
  new: (handle) =>
    super(handle)
    
    @setState({
      turret: false
    })

  setTurret: (turret) =>
    @setState({
      turret: turret
    })

  unitWasRemoved: () =>
    if(IsValid(@state!.turret))
      t = componentManager\getComponent(@state!.turret, Turret)
      t and t\_setTower(false)

  hasTurret: () =>
    return IsAlive(@state!.turret)


class Turret extends UnitComponent
  new: (handle) =>
    super(handle)
    @tracker = ObjectTracker(handle)
    @tracker\onChange("command")\subscribe(@\_commandChanged)
    @tracker\onChange("who")\subscribe(@\_whoChange)
    @setState({
      turretTower: false,
      deployed: false
    })

  _setTower: (tower) =>
    if(IsValid(@state!.turretTower))
      t = componentManager\getComponent(@state!.turretTower, TurretTower) 
      t and t\setTurret(false)

    if(IsValid(tower))
      t = componentManager\getComponent(tower, TurretTower) 
      t and t\setTurret(@getHandle!.handle)
    print(tower, @getHandle!\isDeployed!)
    if((not tower) and @getHandle!\isDeployed!)
      @getHandle!\deploy!
    @setState({
      turretTower: tower,
      deployed: false
    })

  _whoChange: (new, old) =>
    @_commandOrWhoChanged(@getHandle!\getCurrentCommand!, new)

  _commandChanged: (new, old) =>
    @_commandOrWhoChanged(new, @getHandle!\getCurrentWho!)

  _commandOrWhoChanged: (command, who) =>
    if isIn(AiCommand[command], {"GO", "DEFEND"})
      team = GetTeamNum(who)
      turretTower = componentManager\getComponent(who, TurretTower)
      _ref = IsValid(@state!.turretTower) and componentManager\getComponent(@state!.turretTower, TurretTower)
      if(turretTower and (team == @getHandle!\getTeamNum!) and not turretTower\hasTurret())
        @_setTower(who)
        @handle\goto(who,0)
      elseif(_ref and turretTower != _ref)
        @_setTower(false)


    elseif isIn(AiCommand[command],{"FOLLOW", "FORMATION", "RESCUE", "RECYCLE"})
      @_setTower(false)

  update: (dtime) =>
    @tracker\update(dtime)
    if(IsValid(@state!.turretTower))
      _ref = componentManager\getComponent(@state!.turretTower, TurretTower)
      tt = _ref\getHandle!
      if(not @state!.deployed)
        if @getHandle!\isWithin(tt.handle,10) or @getHandle!\getCurrentCommand! == AiCommand["NONE"]
          @getHandle!\dropoff(tt\getPosition!,0)
          @setState({
            deployed: true
          })
      else
        p = tt\getPosition()
        p.y = GetFloorHeightAndNormal(p + SetVector(0,10000000,0))
        @getHandle!\setPosition(p)
        @getHandle!\setVelocity(tt\getVelocity!)
        @getHandle!\setCurAmmo(@getHandle!\getMaxAmmo!)
      
      if((not @getHandle!\isAliveAndPilot! and @getHandle!\isDeployed!) or (not @getHandle!\isDeployed! and @getHandle!.handle == GetPlayerHandle!))
        print("Setting tower to false")
        @_setTower(false)
    elseif((@getHandle!.handle == GetPlayerHandle!) and @getHandle!\isDeployed!)
      for v in ObjectsInRange(25, @getHandle!.handle)
        team = GetTeamNum(v)
        tt = componentManager\getComponent(v, TurretTower)
        if(tt and (team == @getHandle!\getTeamNum!) and not tt\hasTurret())
          @_setTower(v)
          break

  unitWasRemoved: () =>
    @_setTower(false)



class ReactorHealthy extends UnitComponent
  new: (handle) =>
    super(handle)
    h = @getHandle!
    @settings = {
      damagedOdf: h\getProperty("ReactorClass", "damagedReactor"),
      criticalHp: h\getFloat("ReactorClass", "criticalHealth", 0.1),
      meltdownTimer: h\getFloat("ReactorClass", "meltdown", 0),
      radiationRange: h\getFloat("ReactorClass", "radiationRange", 0),
      radiationIntensity: h\getFloat("ReactorClass", "radiationIntensity", 0),
      daywreckerObject: h\getProperty("ReactorClass", "daywreckerObject")
    }
    @tracker = ObjectTracker(handle)
    @sub = {
      @tracker\onChange("health")\subscribe(@\_checkHealth),
      @tracker\onChange("position")\subscribe(@\_posChange)
    }
    @pos = h\getPosition!

  _posChange: (new, old) =>
    if(not isNullPos(new))
      @pos = new

  _checkHealth: (new, old) =>
    h = @getHandle!
    if(new < @settings.criticalHp)
      damagedHandle = h\copyObject(@settings.damagedOdf, h\getTeamNum!, @pos)
      damagedReactor = componentManager\getComponent(damagedHandle, ReactorDamaged)
      if damagedReactor 
        damagedReactor\setSettings(assignObject(@settings, {
          healthyOdf: h\getOdf!
        }),@pos)
      h\removeObject!
  
  update: (dtime) =>
    @tracker\update(dtime)
  
  unitWasRemoved: () =>
    proxyCall(@sub,"unsubscribe")

class ReactorDamaged extends UnitComponent
  new: (handle) =>
    super(handle)
    h = @getHandle!
    @settings = {
      criticalHp: h\getHealth!,
      meltdownTimer: 0,
      radiationRange: 0,
      radiationIntensity: 0
    }
    @tracker = ObjectTracker(handle)
    @sub = {
      @tracker\onDestroy()\subscribe(@\boom),
      @tracker\onChange("health")\subscribe(@\_checkHealth),
      @tracker\onChange("position")\subscribe(@\_posChange)
    }
    @pos = h\getPosition!

  _checkHealth: (new, old) =>
    h = @getHandle!
    if new > @settings.criticalHp and @settings.healthyOdf
      healthyHandle = h\copyObject(@settings.healthyOdf)
      h\removeObject!
  
  _posChange: (new, old) =>
    if(not isNullPos(new))
      @pos = new

  boom: () =>
    h = @getHandle!
    if(@settings.daywreckerObject)
      BuildObject(@settings.daywreckerObject,h\getTeamNum(),@pos)

  setSettings: (settings, pos) =>
    @settings = assignObject(@settings, settings)
    @pos = pos or @pos

  update: (dtime) =>
    @tracker\update(dtime)
    h = @getHandle!
    @remoteUpdate(dtime)

    @settings.meltdownTimer -= dtime
    if @settings.meltdownTimer <= 0
      h\damage(h\getCurHealth!)

  remoteUpdate: (dtime) =>
    h = @getHandle!
    for v in ObjectsInRange(@settings.radiationRange+25, h.handle)
      d = Length(h\getPosition()-GetPosition(v))
      powerup = isIn(GetClassLabel(v),{"ammopack","repairkit","daywrecker","wpnpower","camerapod"})
      if((not powerup) and (v != h.handle) and d <= @settings.radiationRange)
        damage = (@settings.radiationIntensity/math.pow(math.max(d/100,1), 3))*dtime
        Damage(v, damage)
    
  unitWasRemoved: () =>
    proxyCall(@sub,"unsubscribe")

  save: () =>
    return @settings

  load: (settings) =>
    @settings = settings


ComponentConfig(Turret,{
  componentName: "ncim.Turret"
})

ComponentConfig(TurretTower,{
  componentName: "ncim.TurretTower"
})

ComponentConfig(ReactorHealthy,{
  componentName: "ncim.Reactor"
})

ComponentConfig(ReactorDamaged,{
  componentName: "ncim.ReactorDamaged"
})





namespace("ncim", Turret, TurretTower, ReactorDamaged, ReactorHealthy)

return {
  :Turret,
  :TurretTower,
  :ReactorHealthy,
  :ReactorDamaged
}