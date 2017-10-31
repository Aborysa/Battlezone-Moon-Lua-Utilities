utils = require("utils")
core = require("core")
Rx = require("rx")

import Module from utils
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
      @subjects[event.name]\onNext(event)


class EventDispatcherModule extends Module
  new: (...) =>
    super(...)
    @dispatcher = EventDispatcher()
  
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
    super\gameKey(...)
    @dispatcher\dispatch(Event("GAME_KEY",nil,nil,...))

  update: (...) =>
    super\update(...)
    @dispatcher\dispatch(Event("UPDATE",nil,nil,...))

bzApi = core\useModule(EventDispatcherModule)\getDispatcher()

{
  :bzApi,
  :EventDispatcherModule,
  :EventDispatcher
}