utils = require("utils")
coreM = require("core")
Rx = require("rx")
runtime = require("runtime")
objectM = require("object")

CALC_PERIOD = 5



import applyMeta, getMeta, protectedCall, proxyCall, namespace, instanceof, Timer, OdfFile from utils
import Module, core from coreM
import BzObject, objectManager, Handle, ObjectConfig from objectM

import AsyncSubject from Rx




class PathFinder extends BzObject
  new: () =>
    @timer = Timer(10)
    @timer\onAlarm()\subscribe(@done)
    @finished = false
    @sub = AsyncSubject()
    @accDist = 0
    @accTime = 0
    super\onChange("position")\subscribe(@posChange)
    super\onChange("command")\subscribe(@comChange)

  setTarget: (pos) =>
    @accTime = 0
    @accDist = 0
    @target = pos
    super\handle()\goto(@target)

  update: (dtime) =>
    super\update(dtime)
    @accTime += dtime
    @sub\onNext(@accTime,@accDist)


  posChange: (new,old) =>
    @accDist += Length(new-old)

  comChange: (new,old) =>
    if(new == AiCommand["NONE"])
      @done()
  
  onFinish: () =>
    return @sub

  done: () =>
    if(not @finished)
      @finished = true
      @sub\onComplete()
      super\handle()\removeObject()


ObjectConfig(PathFinder,{
  customClass: "pathfinder"
})

objectManager\useClass(PathFinder)

findClosest = (f,vertecies) ->
  count = 0
  sub = AsyncSubject()
  handles = {}
  done = false
  for i, v in pairs(vertecies)
    count+=1
    h = BuildObject("vpfind",0,f)
    i = objectManager\getInstance(h,PathFinder)
    table.insert(handles,h)
    i\onFinish()\subscribe( (t,d) ->
      count-=1
      for i2, v2 in pairs(handles)
        RemoveObject(v2)
      if not done
        done = true
        sub\onNext(v,t,d)
    )

  return sub


class ScrapField
  new: (scrap_p) =>
    @scrapCount = 0
    @scrap = {}
    @addScrap(scrap_p)
    @refresh()
    @refTimer = Timer(6,-1)
    @refTimer\onAlarm()\subscribe(@refresh)

  refresh: () =>
    for i,v in pairs(@scrap)
      for h in ObjectsInRange(50,i)
        if(GetClassLabel(h) == "scrap")
          @addScrap(h)

  addScrap: (handle) =>
    if (getMeta(handle).scrapfield == nil)
      applyMeta(handle,{
        scrapfield: @
      })
      if not @scrap[handle]
        @scrapCount+=1
      @scrap[handle] = true

  removeScrap: (handle) =>
    if @scrap[handle]
      @scrapCount-=1
      applyMeta(handle,{
        scrapfield: nil
      })
    @scrap[handle] = nil


  getScrapCount: () =>
    return @scrapCount


class TestAiManager
  new: (team) =>
    @team = team
    @objects = {}
    --objects by class
    @byclass = {}
    --produers, will contain build lists
    @producers = {}
    @recalc_timer = Timer(5,-1)
    @recalc_timer\onAlarm()\subscribe(@reCalc)

  init: () =>
    @recycler = GetRecyclerHandle()
    for v in AllObjets()
      if(GetTeamNum(v) == @team)
        @regObject(v)

    @recalc_timer\start()

  regObject: (handle) =>
    clabel = GetClassLabel(handle)
    @byclass[clabel] = @byclass[clabel] or {}
    @byclass[clabel][handle] = true
    @objects[handle] = true


  update: (dtime) =>

  reCalc: () =>
    --Find points of interest
    --Change strat, etc


