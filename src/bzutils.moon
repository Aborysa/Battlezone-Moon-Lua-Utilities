service = require("service")
utils = require("utils")
event = require("event")
core = require("core")
net = require("net")
component = require("component")
bz_handle = require("bz_handle")
runtime = require("runtime")


import Module from utils

import ComponentManager from component
import NetworkInterfaceManager from net
import RuntimeController from runtime
import EventDispatcherModule from event


bz1Setup = () ->
  serviceManager = service.ServiceManager()
  core = Module()
  event = core\useModule(EventDispatcherModule, serviceManager)
  net = core\useModule(EventDispatcherModule, serviceManager)
  componentManager = core\useModule(ComponentManager, serviceManager)
  runtimeManager = core\useModule(RuntimeController, serviceManager)

  serviceManager\createService(event, "bzutils.bzapi")
  serviceManager\createService(net, "bzutils.net")
  serviceManager\createService(componentManager, "bzutils.component")
  serviceManager\createService(runtimeManager, "bzutils.runtime")

  return {
    :core,
    :serviceManager
  }

bz2Setup = () ->

defaultSetup = () ->
  if IsBzr() or IsBz15()
    return bz1Setup()
  elseif IsBz2
    return bz2Setup()






return {
  :defaultSetup,
  :bz1Setup,
  :bz2Setup,
  :bz_handle,
  :utils,
  :component,
  :runtime,
  :event,
  :service
}