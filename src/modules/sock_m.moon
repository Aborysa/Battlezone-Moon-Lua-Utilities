-- support module for interfacing with bzext
Module = require("module")
rx = require("rx")


class NetSocketModule extends Module
  new: (parent, serviceManager) =>
    super(parent, serviceManager)
    @serviceManager = serviceManager
    @sockets = {}
    @nextId = 1
    @subscriptions = {}

  update: () =>
    for i, v in pairs(@sockets)
      if not v\isClosed()
        v\_update()
      else
        @unregSocket(i)
  
  unregSocket: (id) =>
    if @subscriptions[id]
      @subscriptions[id]\unsubscribe()
    
    @sockets[id] = nil

  handleSocket: (socket) =>
    id = @nextId
    @nextId += 1
    @sockets[id] = socket
    if socket.mode == "ACCEPT"
      sub = socket\accept()\subscribe(@\handleSocket, nil, nil)
      @subscriptions[id] = sub


return {
  :NetSocketModule,
  :getUserId,
  :getAppInfo,
  :readString,
  :writeString,
}