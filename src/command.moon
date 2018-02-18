
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