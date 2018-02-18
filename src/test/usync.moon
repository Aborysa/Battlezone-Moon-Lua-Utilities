-- "Deployabe producer"
-- Producer that can be deployed anywhere


bzutils = require("bzutils")
rx = require("rx")
utils = bzutils.utils
component = bzutils.component

bz_handle = bzutils.bz_handle

import namespace, isIn, assignObject, proxyCall, isNullPos, local2Global, global2Local from utils
import UnitComponent, SyncedUnitComponent, ComponentConfig from component

import ObjectTracker, Handle from bz_handle

import Observable from rx


class WingmanSlave extends SyncedUnitComponent
  new: (handle, props) =>
    super(handle, props)
    @objTracker = ObjectTracker(handle)
  
  postInit: () =>
    super()
    @sub2 = @getStore()\flatMap((store) -> 
      return store\onKeyUpdate())\subscribe(
        (k,v) -> 
          print("->",k, v)
      )

  update: (dtime) =>
    @objTracker\update(dtime)

  componentWillUnmount: () =>
    super()
    @sub2\unsubscribe()

class Wingman extends WingmanSlave 
  new: (handle, props) =>
    super(handle, props)
    @objTracker = ObjectTracker(handle)
    @setState({
      tcount: 0,
      timer: 0
    })
    @acc = 0

  postInit: () =>
    super()
    @sub1 = @objTracker\onChange("command")\subscribe((c) ->
      @setState({
        command: c
      })
    )
    
    @sub3 = @objTracker\onChange("ammo")\subscribe((c) ->
      @setState({
        ammo: c
      })
    )

  unitWillTransfere: () =>
    state = @state()
    @setState({
      tcount: state.tcount + 1
    })
    --super()

  update: (dtime) =>
    @objTracker\update(dtime)
    @acc += dtime
    if @acc > 1 and @getHandle()\isAlive()
      state = @state()
      @setState({
        timer: state.timer + 1
      })
      @acc = 0

  componentWillUnmount: () =>
    super()
    @sub1\unsubscribe()
    @sub3\unsubscribe()

ComponentConfig(Wingman, {
  classLabels: {"wingman"},
  remoteCls: WingmanSlave
})

return {
  :Wingman,
  setup: (serviceManager) ->
    serviceManager\getService("bzutils.component")\subscribe((componentManager) ->
      componentManager\useClass(Wingman)
    )
}

