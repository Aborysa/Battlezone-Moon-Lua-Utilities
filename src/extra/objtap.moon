-- Bz2 like taps for objects, works on all types


-- "Deployabe producer"
-- Producer that can be deployed anywhere


bzutils = require("bzutils")

utils = bzutils.utils
component = bzutils.component

bz_handle = bzutils.bz_handle

import namespace, isIn, assignObject, proxyCall, isNullPos, local2Global, global2Local, str2vec from utils
import UnitComponent, ComponentConfig from component

import ObjectTracker, Handle from bz_handle

TapBase, ObjectTap = nil, nil

class TapBase extends UnitComponent
  new: (handle, props) =>
    super(handle, props)
    @props = props
    @tapOdfs = @getHandle()\getTable("TapBaseClass","tapOdf")
    @tapLocations = [str2vec(vs) for vs in *@getHandle()\getTable("TapBaseClass","tapLocation")]
    @taps = {}

  unitDidSpawn: () =>
    @props.serviceManager\getService("bzutils.component")\subscribe((componentManager) ->
      for i, v in ipairs(@tapLocations)
        tap = {
          handle: BuildObject(@tapOdfs[i], @getHandle()\getTeamNum(), @getHandle()\getPosition()),
          location: v
        }
        tapComponent = componentManager\getComponent(tap.handle, ObjectTap)
        tapComponent\setParent(@getHandle().handle, tap.location)
    )
  


class ObjectTap extends UnitComponent
  new: (handle, props) =>
    super(handle, props)
    @preserveLook = @getHandle()\getBool("TapClass", "preserveLook", true)
    @requireFloor = @getHandle()\getBool("TapClass", "requireFloor", true)
  

  unitDidSpawn: () =>
    if @requireFloor
      @floor = BuildObject("nbfloor", 0, SetVector(0,0,0))
      Hide(@floor)

  moveTap: () =>
    h = @getHandle()
    t = GetTransform(@parent)
    v = GetVelocity(@parent)
    o = GetOmega(@parent)

    nt = t
    if @preserveLook
      t2 = h\getTransform()
      up = SetVector(t.up_x, t.up_y, t.up_z)
      front = SetVector(t2.front_x, t2.front_y, t2.front_z)
      nt = BuildOrthogonalMatrix(up, front)

    @getHandle()\setTransform(nt)
    pos = local2Global(@location, t) + GetPosition(@parent)
    
    if IsValid(@floor)
      SetPosition(@floor, pos)
      pos.y = GetFloorHeightAndNormal(pos)

    @getHandle()\setVelocity(v)
    @getHandle()\setPosition(pos)


  setParent: (parentHandle, location) =>
    @parent = parentHandle
    @location = location

  update: (dtime) =>
    @moveTap()

  unitWasRemoved: () =>
    if IsValid(@floor)
      RemoveObject(@floor)


return {
  :TapBase,
  :ObjectTap,
  defaultConf: () ->
    ComponentConfig(TapBase,{
      componentName: "TapBase"
    })
    ComponentConfig(ObjectTap,{
      componentName: "ObjectTap"
    })
}

