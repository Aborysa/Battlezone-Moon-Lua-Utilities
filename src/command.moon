-- Component life cycle:
-- constructed/init - called on init
-- postInit - called after init/constructor and load
-- unitDidSpawn - called when/if the unit spawns
-- unitWasRemoved - called when the unit is removed
-- componentWillUnmount - called when the component is removed
-- unitWillTransfere - called when the component is about to be removed due to the unit having switched machine
-- unitDidTransfere - called after postInit when a component has been attached to a handle due to switching machine
-- update - runs ~every update


--UnitBehaviour:-- Component life cycle:
-- constructed/init - called on init
-- postInit - called after init/constructor and load
-- unitDidSpawn - called when/if the unit spawns
-- unitWasRemoved - called when the unit is removed
-- componentWillUnmount - called when the component is removed
-- unitWillTransfere - called when the component is about to be removed due to the unit having switched machine
-- unitDidTransfere - called after postInit when a component has been attached to a handle due to switching machine
-- update - runs ~every update


--UnitBehaviour:

-- only runs for ai controlled craft
-- has listeners to the handle's state
-- only runs locally
-- does not sync state
-- can queue tasks

utils = require("utils")
bz_handle = require("bz_handle")
core = require("core")
net = require("net").net

rx = require("rx")

import Observable from rx
import Module, applyMeta, getMeta, proxyCall, protectedCall, namespace, instanceof, isIn, assignObject, getFullName, Store from utils
import Handle from bz_handle



class CommandManager extends Module
  new: (parent) =>
    super(parent)
    @commands = {}
  
  start: (...) =>


  update: (...) =>

  command: (command, a = "") =>
    ret = {pcall(() -> 
      args = {}
      for arg in a:gmatch("%w+")
        table.insert(args, arg)

      if @commands[command]
        return
    )}
    table.remove(ret,1)
    return unpack(ret)

namespace("component",ComponentManager, UnitComponent)
commandManager = core\useModule(CommandManager)


return {
  :CommandManager,
  :commandManager
}