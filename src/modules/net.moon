
rx = require("rx")
utils = require("utils")
runtime = require("runtime")


import assignObject, namespace, Store, sizeof, sizeTable, simpleIdGeneratorFactory from utils
import Subject, AsyncSubject, ReplaySubject from rx
import Timer from runtime


MAX_INTERFACE = 5000

MAX_SENDSIZE = IsBz15() and 200 or 2000

--Notes:
--NetworkInterface uses replay subject making it remember all network data
--this might cause memory issues for interfaces open for longer amounts of time


--serializes table so it can be sent regerdless of size



netSerializeTable = (tbl, idgen=simpleIdGeneratorFactory(), keymap={}) ->
  id = idgen()
  keymap[id] = {}
  size = 0
  --if sizeof(tbl) < MAX_SENDSIZE
    --return {table.pack(id, 1, tbl)}, keymap

  children = {}
  parts = {}
  cpart = 0
  for i, v in pairs(tbl)
    if size==0
      size = 2
      cpart = cpart + 1
      parts[cpart] = {}

    size = size + sizeof(i) + 1
    if type(v) == "table"
      --size = size + sizeTable["number"](MAX_SENDSIZE)
      _children = netSerializeTable(v, idgen, keymap)
      _child = _children[#_children]
      _cid = _child[1]
      keymap[id][i] = _cid
      for i2, v2 in ipairs(_children)
        table.insert(children, v2)
    else
      size = size + sizeof(v)
      parts[cpart][i] = v
    if size >= MAX_SENDSIZE

      size = 0
  table.insert(children, table.pack(id, cpart, unpack(parts, 1, cpart)))
  return children, keymap



addedPlayers = 0

txRate = 0
totalTx = 0

_Send = Send


-- only send data if there are other players in game
export Send = (...) ->
  if addedPlayers > 0
    _Send(...)
    totalTx += 1
    txRate += 1




class NetworkInterface
  new: (interface_id, to) =>
    @id = interface_id
    @to = type(to) == "number" and {to} or assignObject({},to)
    @subject = ReplaySubject.create()
    @alive = true

  send: (...) =>
    if @alive
      for i, v in pairs(@to)
        Send(v, "N", @id, ...)
    else
      error("Trying to send something via a closed network interface")

  getMessages: () =>
    @subject

  receive: (...) =>
    if @alive
      @subject\onNext(...)

  close: () =>
    if @alive
      @subject\onCompleted()
      @alive = false
    else
      error("Interface has already closed")

  isOpen: () =>
    @alive

  getId: () =>
    @id


class NetPlayer
  new: (id, name, team) =>
    @id = id
    @name = name
    @team = team
    @handle = GetPlayerHandle(team)
    @handleSubject = Subject.create() --ReplaySubject.create()

  getHandle: () => @handle
  getName: () => @name
  getId: () => @id
  getTeam: () => @team
  setHandle: (h) =>
    @handle = h



class Socket
  new: (interface, notify) =>
    @interface = interface
    @connectSubject = Subject.create()
    @receiveSubject = Subject.create()
    @incomingBuffer = {}
    @incomingQueueSize = 0
    @queue = {}
    @_currentId = 1
    @alive =  true
    @closeWhenEmpty = false
    @interface\getMessages()\subscribe(@\receive, nil, @\close)
    if notify
      @interface\send("C")

  _getNextId: () =>
    @_currentId += 1
    return @_currentId

  send: (...) =>
    package = table.pack(...)
    if(#package < 1)
      error("Can not send empty packages")
    package._head = 0
    package._id = @_getNextId()
    package._sub = AsyncSubject.create()
    table.insert(@queue,package)
    return package._sub

  sendNext: () =>
    if @alive
      p = @queue[1]
      if p
        d = #p

        tsize = 0
        sendLen = 1
        if p._head > 0
          for _=1, d
            s = sizeof(p[_])
            if s + tsize < MAX_SENDSIZE
              tsize += s
              sendLen += 1
            else
              break
          d = table.pack(unpack(p, p._head, p._head + sendLen))
        if type(d) == "table"
          @interface\send("P", p._head, p._id, unpack(d))
        else
          @interface\send("P", p._head, p._id, d)
        p._head += sendLen
        if(p._head > #p)
          p._sub\onNext(p._id)
          p._sub\onCompleted()
          table.remove(@queue,1)
      elseif @closeWhenEmpty and @incomingQueueSize <= 0
        @close()
  -- when someone else connects
  onConnect: () =>
    return @connectSubject

  receive: (f,tpe,t,id,...) =>
    if @alive
      @incomingBuffer[f] = @incomingBuffer[f] or {}
      buffer = @incomingBuffer[f]
      if tpe == "P"
        if t == 0
          size = ...
          buffer[id] = [0 for i=1, size]
          @incomingQueueSize += 1
        elseif buffer[id] ~= nil
          data = table.pack(...)
          for _=1, #data do
            buffer[id][t] = data[_]
            t+=1
            if t > #buffer[id]
              break

          if t >= #buffer[id]
            @receiveSubject\onNext(unpack(buffer[id],1,#buffer[id]))
            buffer[id] = nil
            @incomingQueueSize -= 1
      elseif tpe == "C"
        @connectSubject\onNext(f)

  onReceive: () =>
    return @receiveSubject

  getInterface: () =>
    @interface

  isOpen: () =>
    @alive

  closeOnEmpty: () =>
    @closeWhenEmpty = true

  close: () =>
    @alive = false
    @receiveSubject\onCompleted()
    @connectSubject\onCompleted()
    @incomingBuffer = {}
    if @interface\isOpen()
      @interface\close()


-- temporary server socket, might want to create a better server-client architecture later
-- is rather hacky too
class ServerSocket extends Socket
  new: (...) =>
    super(...)
    @onConnect()\subscribe(@\_onConnect)
    @subSockets = {}

  _onConnect: (to) =>
    @subSockets[to] = Socket(NetworkInterface(@interface\getId(), to))

  receive: (f,tpe,t,id,...) =>
    if @alive
      @incomingBuffer[f] = @incomingBuffer[f] or {}
      buffer = @incomingBuffer[f]
      if tpe == "P"
        if t == 0
          size = ...
          buffer[id] = [0 for i=1, size]
          @incomingQueueSize += 1
        elseif buffer[id] ~= nil
          data = table.pack(...)
          for _=1, #data do
            buffer[id][t] = data[_]
            t+=1
            if t > #buffer[id]
              break
          if t >= #buffer[id]
            @receiveSubject\onNext(@subSockets[f],unpack(buffer[id],1,#buffer[id]))
            buffer[id] = nil
            @incomingQueueSize -= 1
      elseif tpe == "C"
        @connectSubject\onNext(f)

  sendNext: (...) =>
    super(...)
    for i, v in pairs(@subSockets)
      v\sendNext(...)

class BroadcastSocket extends Socket
  new: (...) =>
    super(...)
    @onReceive()\subscribe(super\send)





class NetworkInterfaceManager
  new: (parent, serviceManager) =>
    @serviceManager = serviceManager
    @networkInterfaces = {}
    -- our machines id
    @machine_id = -1
    -- the next interface id
    @nextInterface_id = 0
    -- subject that fires once networking is ready
    @networkReadySubject = ReplaySubject.create(1)
    -- subject that fires when a new host is selected
    @hostMigrationSubject = Subject.create()
    @isHostMigrating = false
    @network_ready = false
    -- the sockets that are listening for connections
    @serverSockets = {}
    -- recycled interface ids
    @availableIDs = {}
    -- sockets that we request to listen to
    @requestSockets = {}
    @requestSocketsIds = {}
    @playerInterfaceMap = {}
    @nextRequestId = 0
    @hostPlayer = nil

    @playerHandles = {}
    @playerTargets = {}

    @allSockets = {}
    @playerCount = 0
    @players = {}
    @lastPlayer = {}

    @phandle = GetPlayerHandle()
    @ptarget = GetUserTarget()

    @totalRx = 0
    @rxRate = 0

  getTotalTx: () =>
    return totalTx

  getTotalRx: () =>
    return @totalRx

  getRxRate: () =>
    return @rxRate

  getTxRate: () =>
    return txRate

  getLocalPlayer: () =>
    if not @isNetworkReady
      error("Unknown! Network is not ready")
    return @localPlayer

  getPlayer: (id) =>
    if not @isNetworkReady
      error("Unknown! Network is not ready")
    return @players[id]


  getPlayerHandle: (team) =>
    IsValid(GetPlayerHandle(team)) and GetPlayerHandle(team) or @playerHandles[team or 0]

  getTarget: (handle) =>
    IsValid(GetTarget(handle)) and GetTarget(handle) or @playerTargets[handle]

  isNetworkReady: () =>
    return @network_ready

  onNetworkReady: () =>
    return @networkReadySubject

  onHostMigration: () =>
    return @hostMigrationSubject

  getInterfaceById: (id) =>
    @networkInterfaces[id]

  _getOrCreateInterface: (id, to) =>
    i = @getInterfaceById(id)
    if i == nil
      i = NetworkInterface(id, to)
      if @playerInterfaceMap[to] == nil
        @playerInterfaceMap[to] = {}
      @playerInterfaceMap[to][id] = true
      @networkInterfaces[id] = i
      i\getMessages()\subscribe(nil, nil, () ->
        @playerInterfaceMap[to][id] = nil
        @networkInterfaces[id] = nil
        @allSockets[id] = nil
      )
    return i

  _terminateInterface: (interface_id) =>
    Send(0, "X", interface_id)
    @allSockets[interface_id] = nil
    @networkInterfaces[interface_id] = nil
    table.insert(@availableIDs,id)


  -- cleans up all sockets and network interfaces after a player has left
  _cleanUpInterfaces: (player) =>


  createNewInterface: (to) =>
    id = nil
    if #@availableIDs <= 0
      @nextInterface_id = @nextInterface_id % (MAX_INTERFACE + 1)  + 1
      id = @nextInterface_id + @machine_id * MAX_INTERFACE
      i = @getInterfaceById(id)
      -- if interface exists and it is open, that means we've used up all our interfaces, time to recycle
      if (i and i\isOpen())
        id = nil
        for i, v in pairs(@networkInterfaces)
          if not v\isOpen()
            table.insert(@availableIDs,i)

    if id == nil and #@availableIDs > 0
      id = table.remove(@availableIDs)

    if id ~= nil
      @networkInterfaces[id] = NetworkInterface(id, to)
      @networkInterfaces[id]\getMessages()\subscribe(nil,nil,() ->
        @_terminateInterface(id)
      )
      return @networkInterfaces[id]
    else
      error("All network interfaces used up!")

  _getLeaf: (tbl,...) =>
    t = {...}
    leaf = nil
    curr = tbl
    for v in *t
      if curr[v] == nil
        curr[v] = {}
      leaf = curr[v]
      curr = leaf
    return leaf



  openSocket: (to, socket_type=Socket, ...) =>
    if @network_ready
      leaf = @_getLeaf(@serverSockets,...)
      i = @createNewInterface(to)
      socket = socket_type(i)
      @allSockets[i\getId()] = socket

      if leaf
        if leaf.__socket
          error("Can not have multiple sockets on one channel")
        leaf.__socket = socket
        leaf.__socket\onReceive()\subscribe(nil,nil,() ->
          print("Leaf: socket closed")
          leaf.__socket = nil
        )
        return leaf.__socket
      else
        -- open socket without channel
        return socket
        --error("No channels provided")
    else
      error("Network is not ready")

  getHeadlessSocket: (to, interface_id, socket_type=Socket) =>
    s = socket_type(@_getOrCreateInterface(interface_id, to), true)
    @allSockets[interface_id] = s
    return s

  getRemoteSocket: (...) =>
    leaf = @_getLeaf(@requestSockets, ...)
    if leaf
      if leaf.__socketSubject == nil
        @nextRequestId += 1
        requestId = @nextRequestId
        leaf.__socketSubject = AsyncSubject.create()
        t = Timer(2, -1, @serviceManager)
        args = {...}
        @requestSocketsIds[requestId] = {
          sub: leaf.__socketSubject,
          leaf: leaf,
          timer: t,
          subscription: t\onAlarm()\subscribe((t, life) ->
            if life == 0
              leaf.__socketSubject\onNext(nil)
              leaf.__socketSubject\onCompleted()
              leaf.__socketSubject = nil
              @requestSocketsIds[requestId] = nil
            Send(0, "R", requestId, unpack(args))
          )
        }
        t\start()
        Send(0, "R", @nextRequestId, ...)
      return leaf.__socketSubject
    else
      error("No channels provided")

  receive: (f, t, a, ...) =>
    -- network interface package
    if @localPlayer and @localPlayer.id == f
      return

    @totalRx += 1
    @rxRate += 1

    if t == "N"
      i = @_getOrCreateInterface(a, f)
      i\receive(f,...)
    elseif t == "X"
      i = @getInterfaceById(a)
      if i
        i\close()

    elseif t == "R"
      leaf = @_getLeaf(@serverSockets,...)
      if leaf and leaf.__socket
        Send(f, "C", a, leaf.__socket\getInterface()\getId())

    elseif t == "C"
      if @requestSocketsIds[a]
        interface_id = ...
        r = @requestSocketsIds[a]
        r.subscription\unsubscribe()
        r.timer\stop()
        s = Socket(@_getOrCreateInterface(interface_id, f), true)
        s\onReceive()\subscribe(nil,nil,() ->
          r.leaf.__socketSubject = nil
        )
        @allSockets[interface_id] = s
        r.sub\onNext(s)
        r.sub\onCompleted()
        @requestSocketsIds[a] = nil

    elseif t == "I"
      if @machine_id == -1
        @machine_id = a
        @localPlayer = @players[@machine_id]
        if IsHosting()
          @hostPlayer = @localPlayer

    elseif t == "H"
      @hostPlayer = @players[f] or {id: f, name: "Unknown", team: 0}
      if @isHostMigrating
        @hostMigrationSubject\onNext(@hostPlayer)
        @isHostMigrating = false

    elseif t == "Q"
      p = @getPlayer(f)
      target = ...
      if p
        @playerHandles[p.team] = a or GetPlayerHandle(p.team)
        ph = @getPlayerHandle(p.team)
        if IsValid(ph)
          @playerTargets[ph] = target

    if @hostPlayer~=nil and @machine_id~=-1 and not @network_ready
      print("Network is now ready")
      @network_ready = true
      @networkReadySubject\onNext()
      --@networkReadySubject\onCompleted()

  start: () =>
    if IsNetGame() and not @network_ready and @playerCount <= 1
      @machine_id = @lastPlayer.id
      @localPlayer = @lastPlayer
      @network_ready = true
      @hostPlayer = @localPlayer
      @networkReadySubject\onNext()
      --@networkReadySubject\onCompleted()
    elseif not IsNetGame()
      @machine_id = 0
      @localPlayer = {name: "Player", team: 1, id: 0}
      @hostPlayer = @localPlayer
      @network_ready = true
      @networkReadySubject\onNext()
      --@networkReadySubject\onCompleted()

  update: (dtime) =>

    @rxRate -= dtime
    txRate -= dtime

    @rxRate = math.max(@rxRate, 0)
    txRate = math.max(txRate, 0)
    

    for i, v in ipairs(@requestSocketsIds)
      v.timer\update(dtime)

    for i, v in pairs(@allSockets)
      v\sendNext()

    if @isHostMigrating and IsHosting()
      @hostPlayer = @localPlayer
      @isHostMigrating = false
      @hostMigrationSubject\onNext(@hostPlayer)
      Send(0, "H")

    ph = GetPlayerHandle()
    pt = GetUserTarget()
    if ph ~= @phandle or pt ~= @ptarget
      Send(0, "Q", ph, pt)
    @phandle = ph
    @ptarget = pt

  addPlayer: (id, name, team) =>
    print("Player added!",id,name,team)
    addedPlayers += 1
    @playerInterfaceMap[id] = {}
    if IsHosting() then
      Send(id, "H")
    Send(id, "I", id)
    Send(id, "Q", @phandle, @ptarget)

  createPlayer: (id, name, team) =>
    @playerCount += 1
    @players[id] = {:id, :name, :team}
    @lastPlayer = @players[id]
    --table.insert(@players,{:id,:name,:team})

  deletePlayer: (id, name, team) =>

    addedPlayers -= 1
    for i, v in pairs(@playerInterfaceMap[id] or {}) do
      @_getOrCreateInterface(i)\close()

    if id == (@hostPlayer or {id: -1}).id
      @isHostMigrating = true
    @players[id] = nil



class SharedStore extends Store
  new: (initial_state, socket) =>
    super(initial_state)
    @socket = socket
    @internal_store = Store(initial_state)
    @active = true
    --@extUpdate =  --super\onStateUpdate()\merge()
    --@extKeyUp = --super\onKeyUpdate()\merge(@internal_store\onKeyUpdate())
    --@internal_store\onKeyUpdate()\subscribe((key, value) ->
    --  print("Internal store set", key, value)
    --)
    super\onKeyUpdate()\subscribe((k, v) ->
      if not @active return
      print("Sending", k, v)
      if v == nil
        @socket\send("DELETE", k)
        @internal_store\delete(k)
      else
        @socket\send("SET", k, v)
        @internal_store\set(k, v)
    )

    @socket\onReceive()\subscribe((what, ...) ->
      if not @active return
      if what == "SET"
        @silentSet(...)
        @internal_store\set(...)
      elseif what == "DELETE"
        @silentDelete(...)
        @internal_store\delete(...)
    )

    @socket\onConnect()\subscribe(
      () ->
        if not @active return
        s = @getState()
        for i, v in pairs(s)
          @socket\send("SET", i, v)
      nil,() -> @active = false)

  onStateUpdate: () =>
    @internal_store\onStateUpdate()

  onKeyUpdate: () =>
    @internal_store\onKeyUpdate()



namespace("net",Socket, NetworkInterface, NetworkInterfaceManager)

return {
  :Socket,
  :BroadcastSocket,
  :ServerSocket,
  :NetworkInterface,
  :NetworkInterfaceManager,
  :SharedStore,
  :netSerializeTable,
}
