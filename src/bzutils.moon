service = require("service")
utils = require("utils")
event = require("event")
net = require("net")
component = require("component")
bz_handle = require("bz_handle")
runtime = require("runtime")
ecs = require("ecs_module")
Module = require("module")

import ComponentManager from component
import NetworkInterfaceManager from net
import RuntimeController from runtime
import EventDispatcherModule from event
import EntityComponentSystemModule from ecs


bz1Setup = (use_bzext=true, modid) ->
  serviceManager = service.ServiceManager()
  core = Module()
  event = core\useModule(EventDispatcherModule, serviceManager)
  net = core\useModule(NetworkInterfaceManager, serviceManager)
  componentManager = core\useModule(ComponentManager, serviceManager)
  runtimeManager = core\useModule(RuntimeController, serviceManager)
  ecs = core\useModule(EntityComponentSystemModule, serviceManager)

  serviceManager\createService("bzutils.bzapi", event)
  serviceManager\createService("bzutils.net", net)
  serviceManager\createService("bzutils.component", componentManager)
  serviceManager\createService("bzutils.runtime", runtimeManager)
  serviceManager\createService("bzutils.ecs", ecs)

  if use_bzext
    dloader = require("dloader")
    dll_and_addon = not modid

    assert(dloader.initLoader(modid, dll_and_addon, dll_and_addon), "Failed to init dll loader")
    
    sock = require("sock_m")
    
    
    --bzext_m.initBzExt()
    sockModule = core\useModule(sock.NetSocketModule, serviceManager)
    serviceManager\createService("bzutils.socket", sockModule)

  return {
    :core,
    :serviceManager
  }

bz2Setup = () ->

defaultSetup = (use_bzext=true, modid) ->
  if IsBzr() or IsBz15()
    return bz1Setup(use_bzext, modid)
  elseif IsBz2
    return bz2Setup(use_bzext, modid)






return {
  :defaultSetup,
  :bz1Setup,
  :bz2Setup,
  :bz_handle,
  :utils,
  :component,
  :runtime,
  :event,
  :service,
  :net,
  :ecs
}
