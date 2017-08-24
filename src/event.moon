utils = require("utils")
coreM = require("core")
Rx = require("rx")

import Module, core from coreM
import Subject from Rx

class Event
  new: (name,source,target,...) =>
    @name = name
    @source = source
    @target = target
    @args = table.pack(...)
  
  getArgs: () =>
    unpack(@args)
  
  getName: () =>
    @name

  getSource: () =>
    @source

  getTarget: () =>
    @target

class EventDispatcher
  new: () =>
    @subjects = {}

  on: (event) =>
    if(not @subjects[event])
      @subjects[event] = Subject.create()
    return @subjects[event]

  dispatch: (event) =>
    if(@subjects[event.name])
      @subjects[event]\onNext(event)


class EventDispatcherModule extends Module
  new: () =>
    @dispatcher = EventDispatcher
  
  getDispatcher: () =>
    @dispatcher

  addObject: (...) =>
    super\addObject(...)
    @dispatcher\dispatch(Event("ADD_OBJECT",nil,nil,...))

  createObject: (...) =>
    super\createObject(...)
    @dispatcher\dispatch(Event("CREATE_OBJECT",nil,nil,...))

  deleteObject: (...) =>
    super\deleteObject(...)
    @dispatcher\dispatch(Event("DELETE_OBJECT",nil,nil,...))

  addPlayer: (...) =>
    super\addPlayer(...)
    @dispatcher\dispatch(Event("ADD_PLAYER",nil,nil,...))

  createPlayer: (...) =>
    super\createPlayer(...)
    @dispatcher\dispatch(Event("CREATE_PLAYER",nil,nil,...))

  deletePlayer: (...) =>
    super\deletePlayer(...)
    @dispatcher\dispatch(Event("DELETE_PLAYER",nil,nil,...))

  gameKey: (...) =>
    proxyCall(@submodules,"gameKey",...)
    @dispatcher\dispatch(Event("GAME_KEY",nil,nil,...))


bzApi = core\useModule(EventDispatcherModule)\getDispatcher()

{
  :bzApi,
  :EventDispatcherModule,
  :EventDispatcher
}