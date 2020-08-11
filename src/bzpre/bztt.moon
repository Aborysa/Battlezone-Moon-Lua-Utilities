rx = require("rx")
utils = require("utils")
json = require("json"
)
import Subject, AsyncSubject from rx

import simpleIdGeneratorFactory from utils

requireDlls = require("dloader").requireDlls

socket = nil



requireDlls("socket")\subscribe((sock) ->
  socket = sock
)



T_CONNECT = 1
T_CONNECT_ACK = 2
T_DISCONNECT = 3
T_DISCONNECT_ACK = 4
T_SUBSCRIBE = 5
T_SUBSCRIBE_ACK = 6
T_UNSUBSCRIBE = 7
T_UNSUBSCRIBE_ACK = 8
T_PUBLISH = 9
T_PUBLISH_ACK = 10
T_PUSH = 11



-- using little endian
class WriteBuffer
  new: (buffer={}) => 
    @buffer = buffer
  
  -- big endian ABCD -> [A, B, C, D]
  putNumber: (number, bytes=math.ceil(math.max(math.log(number)/math.log(255), 1))) =>
    ibuff = {}
    for i=1, bytes
      part = bit.band(bit.rshift(number, (bytes-i)*8), 0xFF)
      table.insert(ibuff, string.char(part))
    
    table.insert(@buffer, table.concat(ibuff))

  putString: (str) => 
    @putNumber(str\len(), 4)
    table.insert(@buffer, str)
  
  putFloat: (number) =>
    @putString(tostring(number))
  
  putBuffer: (buf) =>
    @putString(buf\bytes())

  putStringArray: (arr) =>
    len = 0
    size = 8
    --calculate size of array
    for i, v in ipairs(arr)
      size += v\len() + 4
      len += 1
    
    @putNumber(size, 4)
    @putNumber(len, 4)
    for i, v in ipairs(arr)
      @putString(v)

  putNumberArray: (arr, bytes) =>
    len = #arr
    size = 8 + arr * bytes

    @putNumber(size, 4)
    @putNumber(len, 4)
    for i, v in ipairs(arr)
      @putNumber(v, bytes)
    
    
  bytes: () =>
    return table.concat(@buffer, "")

class ReadBuffer
  new: (buffer="") => 
    @buffer = buffer
    @cursor = 1

  available: () =>
    return @buffer\len() - (@cursor - 1)

  canRead: (len) => 
    return @available() >= len
  
  backtrack: (len) =>
    @cursor -= len

  append: (buffer) =>
    @buffer ..= buffer

  readByte: () =>
    byte = string.byte(@buffer, @cursor)
    @cursor += 1
    return byte

  readChar: () =>
    char = string.sub(@buffer, @cursor, @cursor)
    @cursor += 1
    return char

  readChars: (len=1) =>
    chars = string.sub(@buffer, @cursor, @cursor+len-1)
    @cursor += len
    return chars

  readNumber: (bytes) =>
    ret = 0
    for i=1, bytes
      b = @readByte()
      ret += bit.lshift(b, (bytes-i)*8)
      
    return ret

  readString: () => 
    len = @readNumber(4)
    return @readChars(len)

  canReadString: () =>
    len = @readNumber(4)
    @backtrack(4)
    return @canRead(len)

  canReadFloat: () =>
    return @canReadString()

  readFloat: () =>
    tonumber(@readString())

  readBuffer: () => 
    data = @readString()
    return ReadBuffer(data)
  -- returns a new readbuffer from offset
  slice: () =>
    return ReadBuffer(@readChars(@available()))

class TcpSocket
  new: (sock=socket.tcp(), timeout=0.005) =>
    @sock = sock
    @sock\settimeout(timeout)
    @mode = "NONE"
    @socketSubject = Subject.create()
    @closed = false
    @sock\setoption("keepalive", true)

  @connect: (...) =>
    sock = socket.tcp()
    res, err = sock\connect(...)
    print(res, err)
    
    return TcpSocket(sock)

  @bind: (...) =>
    sock = socket.tcp()
    res, err = sock\bind(...)
    if err
      return nil
    return TcpSocket(sock)
  

  getstats: () =>
    return @sock\getstats()

  getsockname: () =>
    return @sock\getsockname()
  
  getpeername: () =>
    return @sock\getpeername()

  connect: (...) =>
    return @sock\connect(...)
  
  bind: (...) =>
    return @sock\bind(...)
    
  listen: (...) =>
    return @sock\listen(...)

  send: (...) =>
    return @sock\send(...)
  
  accept: () =>
    @mode = "ACCEPT"
    return @socketSubject
  
  receive: () =>
    @mode = "RECEIVE"
    return @socketSubject

  close: () =>
    @closed = true
    @socketSubject\onCompleted()

  isClosed: () =>
    return @closed

  _update: () =>
    if @closed 
      return
    if @mode == "ACCEPT"
      socket, err = @sock\accept()
      if socket
        @socketSubject\onNext(TcpSocket(socket))

    elseif @mode == "RECEIVE"
      data, err, partial = @sock\receive(2048)
      if data
        @socketSubject\onNext(data)
      
      if err == "timeout" and partial\len() > 0
        @socketSubject\onNext(partial)

      if err == "closed"
        @closed = true
        @socketSubject\onCompleted()



class BZTTClient
  new: (socket) =>
    @socket = socket
    @readBuffer = ReadBuffer()
    @readState = 0
    @nextPack = nil
    @inflightMessages = {}
    @idGenerator = simpleIdGeneratorFactory()
    
    @connected = false
    @connectedUser = nil
    @connecting = false

    @ackSubjects = {}
    @receiveSubject = Subject.create()

    @pushTopicSubjects = {}
    @pushSubject = Subject.create()

    @socket\receive()\subscribe(@\_receive)


  @create: (hostname, port=8889) =>
    socket = TcpSocket\connect(hostname, port)
    return BZTTClient(socket)



  _handleCompleteMessage: (msg) =>
    switch(msg.type)
      when T_CONNECT_ACK, T_DISCONNECT_ACK, T_PUBLISH_ACK, T_SUBSCRIBE_ACK, T_UNSUBSCRIBE_ACK
        msg.payload = msg.payload\readNumber(4)
        if @ackSubjects[msg.id]
          @ackSubjects[msg.id]\onNext(msg)
          @ackSubjects[msg.id]\onCompleted()
        
      when T_PUSH
        msg.payload = {
          topic: msg.payload\readString(),
          message: msg.payload\readString()
        }
        if @pushTopicSubjects[msg.payload.topic]
          @pushTopicSubjects[msg.payload.topic]\onNext(msg.payload.message)
        @pushSubject\onNext(msg.payload.topic, msg.payload.message)


      else
        error("Unknown message type %s"\format(tostring(msg.type)))
    
    
    @receiveSubject\onNext(msg)


  _receive: (data) =>
    @readBuffer\append(data)
    while(true)
      if (@readState == 0) and (@readBuffer\available() >= 9)
        @readState = 1
        @nextPack = {
          type: @readBuffer\readNumber(1),
          id: @readBuffer\readNumber(4)
        }
        
      if (@readState == 1 and (@readBuffer\canReadString()))
        @nextPack.payload = @readBuffer\readBuffer()
        @readBuffer = @readBuffer\slice()
        @_handleCompleteMessage(@nextPack)
        @readState = 0
        continue
      
      break

  sendMessage: (type, payload, id=@idGenerator()) =>
    writeBuffer = WriteBuffer()
    writeBuffer\putNumber(type, 1)
    writeBuffer\putNumber(id, 4)
    writeBuffer\putBuffer(payload)
    
    subject = AsyncSubject.create()
    @ackSubjects[id] = subject
    @socket\send(writeBuffer\bytes())

    return subject

  onReceive: (id) =>
    if id ~= nil
      return @ackSubjects[id]
    return @receiveSubject

  onPush: (topic=nil) =>
    if(topic ~= nil)
      return @pushTopicSubjects[topic]

    return @pushSubject

  connect: (user) =>
    assert(not @connecting, "Already trying to connect...")
    assert(not @connected, "Already connected")
    
    buffer = WriteBuffer()
    buffer\putString(user.clientId)
    buffer\putString(user.username)
    buffer\putNumber(user.userId, 1)
    buffer\putNumber(user.team, 1)

    return @sendMessage(T_CONNECT, buffer)\map(() -> 
      @connected = true
      @connecting = false
      @connectedUser = user

      return user
    )

  
  joinTopic: (...) =>
    topics = {...}
    
    buffer = WriteBuffer()
    buffer\putStringArray(topics)
    for i, v in ipairs(topics)
      @pushTopicSubjects[v] = Subject.create()
      
    return @sendMessage(T_SUBSCRIBE, buffer)\map(() -> 
      return unpack(topics)
    )


  publishTbl: (topic, data) =>
    @publish(topic, json.encode(data))

  publish: (topic, data) => 
    buffer = WriteBuffer()

    buffer\putString(tostring(topic))
    buffer\putString(tostring(data))
    
    return @sendMessage(T_PUBLISH, buffer)\map(() ->
      return topic
    )


return {
  :BZTTClient,
  :TcpSocket,
  :WriteBuffer,
  :ReadBuffer
}
