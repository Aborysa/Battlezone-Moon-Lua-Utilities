service = require("service")
utils = require("utils")
event = require("event")
net = require("net")
component = require("component")
bz_handle = require("bz_handle")
runtime = require("runtime")
ecs = require("ecs_module")
Module = require("module")
objective_m = require("objective_m")

import ComponentManager from component
import NetworkInterfaceManager from net
import RuntimeController from runtime
import EventDispatcherModule from event
import EntityComponentSystemModule from ecs

import ObjectiveModule from objective_m

bz1Setup = () ->
  serviceManager = service.ServiceManager()
  core = Module()
  event = core\useModule(EventDispatcherModule, serviceManager)
  net = core\useModule(NetworkInterfaceManager, serviceManager)
  componentManager = core\useModule(ComponentManager, serviceManager)
  runtimeManager = core\useModule(RuntimeController, serviceManager)
  ecs = core\useModule(EntityComponentSystemModule, serviceManager)
  objectiveManager = core\useModule(ObjectiveModule, serviceManager)

  serviceManager\createService("bzutils.bzapi", event)
  serviceManager\createService("bzutils.net", net)
  serviceManager\createService("bzutils.component", componentManager)
  serviceManager\createService("bzutils.runtime", runtimeManager)
  serviceManager\createService("bzutils.ecs", ecs)
  serviceManager\createService("bzutils.objective", objectiveManager)

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
  :service,
  :net,
  :ecs
}
