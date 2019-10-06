-- module for interfacing with bzext

Module = require("module")

event = require("event")

rx = require("rx")


import EventDispatcher, Event  from event

import AsyncSubject, Subject from rx

bzext = nil

bzext_events = EventDispatcher()




initBzExt = (core) ->
  bzext = require("bzext")





export BzExt_Event = (t, ...) ->
  e = Event(t, "BZEXT", nil, ...)
  bzext_events\queueEvent(e)

_appinfo = nil
getAppInfo = () ->
  if not _appinfo
    _appinfo = bzext.getAppInfo("301650")
  return _appinfo

getUserId = () -> 
  getAppInfo()\gmatch('"LastOwner"%s*"(%d+)"')()
  

httpGet = (url) ->
  requestId = bzext.httpGet(url)
  return bzext_events\on("CALLBACK")\filter((event) ->
    id = event\getArgs()
    return id == requestId
  )\first()\map((event) ->
    _id, _content = event\getArgs()
    return _content
  )

httpPost = (url, data) ->
  print(url, data)
  requestId = bzext.httpPost(url, data)
  return bzext_events\on("CALLBACK")\filter((event) -> 
    id = event\getArgs()
    return id == requestId
  )\first()\map((event) ->
    _id, _content = event\getArgs()
    return _content
  )

writeString = (...) -> bzext.writeString(...)
readString = (...) -> bzext.readString(...)

--todo: finish websocket
class WebSocket
  new: () =>
    -- 0 - not connected, 1 - connecting, 2 - connected, 3 - closing, 4 - closed
    @status = 0

    @connectSubject = AsyncSubject.create()
    @closeSubject = AsyncSubject.create()
    @receiveSubject = Subject.create()

  receive: () =>
    return @receiveSubject

  send: (message) =>
    print("Trying to send", @status)
    
    if @status == 2
      print(@id, message)
      bzext.sendWebSocket(@id, message)

  connect: (url) =>
    if @status == 0
      @status = 1
      @id = bzext.openWebSocket(url)
      @socket_open_sub = bzext_events\on("SOCKET_OPEN")\subscribe((event) ->
        id = event\getArgs()
        if id == @id
          @socket_open_sub\unsubscribe()
          @status = 2
          @connectSubject\onNext()
          @connectSubject\onCompleted()
      )

      @socket_close_sub = bzext_events\on("SOCKET_CLOSE")\subscribe((event) ->
        id = event\getArgs()
        if id == @id
          @socket_close_sub\unsubscribe()
          @status = 4
          @closeSubject\onNext()
          @closeSubject\onCompleted()
          @receiveSubject\onCompleted()
          @socket_message_sub\unsubscribe()
      )

      @socket_message_sub = bzext_events\on("SOCKET_MESSAGE")\subscribe((event) ->
        id, message = event\getArgs()
        if id == @id
          @receiveSubject\onNext(message)
      )

    return @connectSubject


  close: () =>
    if status == 2
      bzext.closeWebSocket(@id)
      status = 3
    return @closeSubject

  onClose: () =>
    return @closeSubject


  getId: () =>
    return @id

  getStatus: () =>
    return @status



class BzExtModule extends Module
  new: (parent, serviceManager) =>
    super(parent, serviceManager)
    @serviceManager = serviceManager

  update: () =>
    bzext.update()
    bzext_events\dispatchQueue()




return {
  :WebSocket,
  :BzExtModule,
  :initBzExt,
  :httpGet,
  :httpPost,
  :getUserId,
  :getAppInfo,
  :readString,
  :writeString
}