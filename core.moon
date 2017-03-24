utils = require("utils")

import assignMeta, getMeta, protectedCall, proxyCall, namespace, getFullName, instanceof from utils




class Module
  new: (parent) =>
    @submodules = {}
    @parent = parent

  start: (...) =>
    proxyCall(@submodules,"start",...)

  update: (...) =>
    proxyCall(@submodules,"update",...)

  addObject: (...) =>
    proxyCall(@submodules,"addObject",...)

  createObject: (...) =>
    proxyCall(@submodules,"createObject",...)

  deleteObject: (...) =>
    proxyCall(@submodules,"deleteObject",...)

  addPlayer: (...) =>
    proxyCall(@submodules,"addPlayer",...)

  createPlayer: (...) =>
    proxyCall(@submodules,"createPlayer",...)

  deletePlayer: (...) =>
    proxyCall(@submodules,"deletePlayer",...)

  save: (...) =>
    return proxyCall(@submodules,"save",...)

  load: (...) =>
    data = ...
    for i, v in pairs(@submodules)
      protectedCall(v,"load",data[i])
  
  gameKey: (...) =>
    proxyCall(@submodules,"gameKey",...)

  useModule: (cls) =>
    inst = cls(@)
    @submodules[getFullName(cls)] = inst
    return inst

namespace("core",Module)

core = Module()

{
  :Module,
  :core
}
