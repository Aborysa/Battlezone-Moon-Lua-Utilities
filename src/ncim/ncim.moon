
bzutils = require("bzutils")

utils = bzutils.utils
component = bzutils.component

bz_handle = bzutils.bz_handle

rx = require("rx")

import namespace, isIn, assignObject, proxyCall, isNullPos, local2Global, global2Local from utils
import UnitComponent, SyncedUnitComponent, ComponentConfig, componentManager from component
import Observable, AsyncSubject from rx
import ObjectTracker, Handle from bz_handle

Turret = nil
TurretTower = nil
ReactorHealthy = nil
ReactorDamaged = nil



class TurretTower extends UnitComponent
  new: (handle, socketSub) =>
    super(handle, socketSub)
    
    @req = nil
    @setState({
      turret: false
    })
    

    if socketSub
      socketSub\subscribe((socket) ->
        print("Got socket")
        @socket = socket
        socket\onReceive()\subscribe(@\receive)
        socket\onConnect()\subscribe(() -> @socket\send("SET_TURR", @state!.turret))
      )


  receive: (what, who) =>
    if what == "REQ_TOWER"
      if not @hasTurret()
        --going to assume the unit is running on this machine
        @setTurret(who)
      elseif not IsAlive(who)
        @setTurret(false)
      @socket\send("SET_TURR", @state!.turret)

    elseif what == "SET_TURR"
      if @req ~= nil
        @req.sub\onNext({@getHandle()\getHandle(),who})
        @req.sub\onCompleted()
        @req = nil
      @setState({
        turret: who
      })

  setTurret: (turret) =>
    print("set turret",turret)
    if IsNetGame() and @getHandle()\isRemote()
      if @req==nil and @socket~=nil
        @req = {
          sub: AsyncSubject.create(),
          turret: turret
        }
        @socket\send("REQ_TOWER", turret)
        return @req.sub
       
      else
        return Observable.of({@getHandle()\getHandle(),@state!.turret})
    else
      @setState({
        turret: turret
      })
      if @socket~=nil
        @socket\send("SET_TURR", turret)

      return Observable.of({@getHandle().handle,turret})


  hasTurret: () =>
    return IsAlive(@state!.turret)


class RemoteTurret extends SyncedUnitComponent
  new: (handle, socketSub) =>
    super(handle, socketSub)
    @setState({
      turretTower: false,
      deployed: false
    })
    @getHandle()\setObjectiveOn()

  postInit: () =>
    @getHandle()\setObjectiveName("Deployed" and @state().deployed or "Not Deployed")
    @getStore()\onKeyUpdate()\subscribe((key, value) ->
      if key == "deployed"
        @getHandle()\setObjectiveName(value and "Deployed" or "Not Deployed")
    )

class Turret extends RemoteTurret
  new: (handle, socketSub) =>
    super(handle, socketSub)
    @tracker = ObjectTracker(handle)
    @tracker\onChange("command")\subscribe(@\_commandChanged)
    @tracker\onChange("who")\subscribe(@\_whoChange)


  _subToTower: (s) =>
    print("sub to tower")
    if @sub
      @sub\unsubscribe()
    @sub = s\subscribe((a) ->
      tower, turr = unpack(a)
      t = false
      if turr == @getHandle!.handle
        t = tower
        @handle\goto(t,0)
      @setState({
        turretTower: t,
        deployed: false
      })
    )

  _setTower: (tower) =>
    print("_set tower", tower)
    ret = Observable.of({false})
    if(IsValid(@state!.turretTower))
      t = componentManager\getComponent(@state!.turretTower, TurretTower) 
      if t
        ret = t\setTurret({false})

    if(IsValid(tower))
      print("Getting component of tower")
      t = componentManager\getComponent(tower, TurretTower) 
      if t
        print("Has component", tower, t, t\hasTurret())
        print(@getHandle!,@getHandle!.handle)
        print("FALSE:",t\setTurret(false))
        ret = t\setTurret(@getHandle!.handle)
        print("Still here!")
    if((not tower) and @getHandle!\isDeployed!)
      @getHandle!\deploy!

    @_subToTower(ret)
    return ret


  _whoChange: (new, old) =>
    @_commandOrWhoChanged(@getHandle!\getCurrentCommand!, new)

  _commandChanged: (new, old) =>
    @_commandOrWhoChanged(new, @getHandle!\getCurrentWho!)

  _commandOrWhoChanged: (command, who) =>
    if isIn(AiCommand[command], {"GO", "DEFEND"})
      team = GetTeamNum(who)
      turretTower = componentManager\getComponent(who, TurretTower)
      _ref = IsValid(@state!.turretTower) and componentManager\getComponent(@state!.turretTower, TurretTower)
      print(turretTower, IsFriend(team,@getHandle!\getTeamNum!),not turretTower\hasTurret())
      if(turretTower and IsFriend(team,@getHandle!\getTeamNum!) and not turretTower\hasTurret())
        @_setTower(who)
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
      criticalHp: h\getFloat("ReactorClass", "criticalHealth", 0.1)
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

class ReactorDamagedRemote extends UnitComponent
  new: (handle) =>
    super(handle)
    h = @getHandle!

    @tracker = ObjectTracker(handle)
    @sub = {
      @tracker\onChange("position")\subscribe(@\_posChange),
      @tracker\onDestroy()\subscribe(@\boom)
    }

    @settings = {
      criticalHp: h\getHealth!,
      meltdownTimer: h\getFloat("ReactorClass", "meltdown", 0),
      radiationRange: h\getFloat("ReactorClass", "radiationRange", 0),
      radiationIntensity: h\getFloat("ReactorClass", "radiationIntensity", 0),
      daywreckerObject: h\getProperty("ReactorClass", "daywreckerObject")
    }
    @pos = h\getPosition!



  boom: () =>
    h = @getHandle!
    if(@settings.daywreckerObject)
      BuildLocal(@settings.daywreckerObject,h\getTeamNum(),@pos)

  setSettings: (settings, pos) =>
    @settings = assignObject(@settings, settings)
    @pos = pos or @pos

  update: (dtime) =>
    h = @getHandle!
    @tracker\update(dtime)
    @settings.meltdownTimer -= dtime
    for v in ObjectsInRange(@settings.radiationRange+25, h.handle)
      d = Length(h\getPosition()-GetPosition(v))
      powerup = isIn(GetClassLabel(v),{"ammopack","repairkit","daywrecker","wpnpower","camerapod"})
      if((not powerup) and (v != h.handle) and d <= @settings.radiationRange)
        damage = (@settings.radiationIntensity/math.pow(math.max(d/100,1), 3))*dtime
        Damage(v, damage)

  save: () =>
    return @settings

  load: (settings) =>
    @settings = settings


  _posChange: (new, old) =>
    if(not isNullPos(new))
      @pos = new


  unitWasRemoved: () =>
    proxyCall(@sub,"unsubscribe")

class ReactorDamaged extends ReactorDamagedRemote
  new: (handle, socketSub) =>
    super(handle, socketSub)
    h = @getHandle!
    table.insert(@sub,@tracker\onChange("health")\subscribe(@\_checkHealth)) 
    --table.insert(@sub,@tracker\onDestroy()\subscribe(@\boom))
    
  _checkHealth: (new, old) =>
    print(new, old)
    h = @getHandle!
    if new > @settings.criticalHp and @settings.healthyOdf
      healthyHandle = h\copyObject(@settings.healthyOdf)
      h\removeObject!
  


  update: (dtime) =>
    super(dtime)
    h = @getHandle!

    if @settings.meltdownTimer <= 0
      h\damage(h\getCurHealth!)




ComponentConfig(Turret,{
  componentName: "ncim.Turret",
  remoteCls: RemoteTurret
})

ComponentConfig(TurretTower,{
  componentName: "ncim.TurretTower",
  remoteCls: TurretTower
})

ComponentConfig(ReactorHealthy,{
  componentName: "ncim.Reactor"
})

ComponentConfig(ReactorDamaged,{
  componentName: "ncim.ReactorDamaged",
  remoteCls: ReactorDamagedRemote
})





namespace("ncim", Turret, TurretTower, ReactorDamaged, ReactorHealthy)

return {
  :Turret,
  :TurretTower,
  :ReactorHealthy,
  :ReactorDamaged
}