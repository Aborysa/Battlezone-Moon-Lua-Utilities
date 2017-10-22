Rx = require("rx")

import Subject, ReplaySubject from Rx

--Consts
metadata = setmetatable({},{__mode: "k"})

--Util functions
_unpack = unpack
_GetOdf = GetOdf
_GetPilotClass  = GetPilotClass
_GetWeaponClass = GetWeaponClass


_BuildObject = BuildObject

if IsNetGame()
  export BuildObject = (...) ->
    h = _BuildObject(...)
    SetLocal(h)
    return h

-- Builds locally no matter what
export BuildLocal = (...) ->
  _BuildObject(...)

export GetOdf = (...) ->
  ( _GetOdf(...) or "" )\gmatch("[^%c]*")()

export GetPilotClass = (...) ->
  ( _GetPilotClass(...) or "")\gmatch("[^%c]*")()

export GetWeaponClass = (...) ->
  ( _GetWeaponClass(...) or "")\gmatch("[^%c]*")()

export SetLabel = SetLabel or SettLabel

export IsFriend = (a, b) ->
  IsTeamAllied(a, b) or a == b


simulatedTime = 0

export GetSimTime = () ->
  simulatedTime

export SimulateTime = (dtime) ->
  simulatedTime += dtime

export GetPathPointCount = GetPathPointCount or (path) ->
  p = GetPosition(path,0)
  lp = SetVector(0,0,0)
  c = 0
  while p ~= lp
    lp = p
    c += 1
    p = GetPosition(path,c)
  return c

export GetPathPoints = (path) ->
  return [GetPosition(path,i) for i=0, GetPathPointCount(path)-1]

export GetCenterOfPolygon = (vertecies) ->
  center = SetVector(0,0,0)
  signedArea = 0
  a = 0
  for i,v in ipairs(vertecies)
    v2 = vertecies[i % #vertecies + 1]
    a = v.x*v2.z - v2.x*v.z
    signedArea += a
    center += SetVector(v.x + v2.x,0,v.z + v2.z)*a

  signedArea /= 2
  center /= 6*signedArea
  return center

export GetCenterOfPath = (path) ->
  GetCenterOfPolygon(GetPathPoints(path))


table.pack = (...) ->
  l = select("#", ...)
  setmetatable({ __n: l, ... }, {__len: () -> l})

export unpack = (t,...) ->
  if(t.__n ~= nil)
    return _unpack(t,1,t.__n)
  return _unpack(t,...)

isIn = (element, list) ->
  for e in *list
    if e == element
      return true
  return false

assignObject = (...) ->
  return {k,v for obj in *{...} for k, v in pairs(obj) }

ommit = (table, fields) ->
  t = {k, v for k, v in pairs(assignObject({},table)) when not isIn(k,fields)}
  

compareTables = (a, b) ->
  {k, v for k, v in pairs(assignObject(a,b)) when a[k] ~= b[k]}
  


isNullPos = (pos) ->
  return pos.x == pos.y and pos.y == pos.z and pos.z == 0

getMeta = (obj) ->
  return {k,v for k,v in pairs(metadata[obj] or {})}

dropMeta = (obj) ->
  metadata[obj] = nil

applyMeta = (obj,...) ->
  metadata[obj] = assignObject(getMeta(obj),...) 

namespace = (name,...) ->
  for i,v in pairs({...})
    applyMeta(v,{
      namespace: name
    })
  return ...

getFullName = (cls) ->
  "#{getMeta(cls).namespace or ""}.#{cls.__name}"



instanceof = (inst,cls) ->
  current = cls
  while current
    if(inst.__class == current)
      return true
    current = current.__parent
  return false


protectedCall = (obj,method,...) ->
  if(obj[method])
    return obj[method](obj,...)
  
proxyCall = (objs,method,...) -> 
  return {i,table.pack(protectedCall(v,method,...)) for i, v in pairs(objs)}

global2Local = (v,t) ->
  up = SetVector(t.up_x, t.up_y, t.up_z)
  front = SetVector(t.front_x, t.front_y, t.front_z)
  right = SetVector(t.right_x, t.right_y, t.right_z)
  return v.x * front + v.y * up + v.z * right

local2Global = (v,t) ->
  up = SetVector(t.up_x, t.up_y, t.up_z)
  front = SetVector(t.front_x, t.front_y, t.front_z)
  right = SetVector(t.right_x, t.right_y, t.right_z)
  return v.x / front + v.y / up + v.z / right

stringlist = (str) ->
  m = str\match "%s*([%.%w]+)%s*,?"
  return unpack([v for v in m])

str2vec = (str) ->
  m = str\gmatch("%s*(%-?%d*%.?%d*)%a*%s*,?")
  return SetVector(m(), m(), m())

getHash = (any) ->
  tonumber {tostring(any)\gsub("%a+: ","")}, 16




--Util classes


class Store
  new: (initial_state) =>
    @state = initial_state or {}
    @updateSubject = ReplaySubject.create(1)
    @keyUpdateSubject = Subject.create()

  set: (key, value) =>
    @assign({[key]: value})

  assign: (kv_pairs) =>
    p_state = @state
    @state = assignObject(@state, kv_pairs)
    for k, v in pairs(compareTables(p_state, kv_pairs))
      @keyUpdateSubject\onNext(k,v)
    @updateSubject\onNext(@state, p_state)

  getState: () =>
    @state

  onStateUpdate: () =>
    @updateSubject

  onKeyUpdate: () =>
    @keyUpdateSubject

--loop = -1, loop infinite times
class Timer
  new: (time,loop=0) =>
    @inf = loop == -1
    @life = loop + 1
    @time = time
    @acc = 0
    @tleft = time
    @running = false
    @alarmSubject = Subject.create()

  _round: () =>
    @reset()
    @life -= 1
    if(@life <= 0 and (not @inf))
      @running = false

    @alarmSubject\onNext(@,math.abs(@life),@acc)

  update: (dtime) =>
    if(@running)
      @acc += dtime
      @tleft -= dtime
      if(@tleft <= 0)
        @_round()

  start: () =>
    if(@life > 0 or @inf)
      @running = true

  setLife: (life) =>
    @life = life

  reset: () =>
    @tleft = @time
  
  stop: () =>
    @pause()
    @reset()

  pause: () =>
    @running = false

  onAlarm: () =>
    return @alarmSubject

  save: () =>
    return @tleft, @acc, @running, @life

  load: (...) =>
    @tleft, @acc, @running, @life = ...

class Area
  new: (path,t="poly") =>
    @areaSubjects = {
      all: Subject.create()
    }
    @type = t
    @path = path
    @handles = {}
        --Calculate center and radius
    @_bounding()
    --register everyone that is inside
    for v in ObjectsInRange(@radius+50,@center)
      if IsInsideArea(@path,v)
        @handles[v] = true


  getPath: () =>
    @path

  getCenter: () =>
    @center
  
  getObjects: () =>
    return [i for i,v in pairs(@handles)]

  getRadius: () =>
    @radius

  _bounding: () =>
    if(@type == "poly")
      center = GetCenterOfPath(@path)
      radius = 0
      for i,v in ipairs(GetPathPoints(@path)) do
        radius = math.max(radius,Length(v-center))
      
      @center = center
      @radius = radius

  update: () =>
    all = {i,1 for i,v in pairs(@handles)}
    for v in ObjectsInRange(@radius+50,@center)
      all[v] = 1
    for v,_ in pairs(all) do
      if IsInsideArea(@path,v)
        if @handles[v] == nil
          @nextObject(v,true)
        @handles[v] = true
      else
        if @handles[v]
          @nextObject(v,false)
        @handles[v] = nil

  nextObject: (handle,inside) =>
    @areaSubjects.all\onNext(@,handle,inside)
    if(@areaSubjects[handle])
      @areaSubjects[handle]\onNext(@,handle,inside)

  onChange: (handle) =>
    if(handle)
      @areaSubjects[handle] = @areaSubjects[handle] or Subject.create()
      return @areaSubjects[handle]

    return @areaSubjects.all

  save: () =>
    return @handles

  load: (...) =>
    @handles = ...

class OdfHeader
  new: (file,name) =>
    @file = file
    @header = name
  
  getProperty: (...) =>
    return GetODFString(@file,@header,...)

  getInt: (...) =>
    return GetODFInt(@file,@header,...)
    
  getBool: (...) =>
    return GetODFBool(@file,@header,...)
    
  getFloat: (...) =>
    return GetODFFloat(@file,@header,...)
    
  getVector: (...) =>
    return str2vec(@getProperty(...) or "")

  getTable: (var,...) =>
    c = 1
    ret = {}
    max = @getInt("#{var}Count", 100)
    n = @getProperty("#{var}#{c}",...)
    while n and c < max
      table.insert(ret,n)
      n = @getProperty("#{var}#{c}",...)
      c += 1
    return ret

class OdfFile
  new: (filename) =>
    @name = filename
    @file = OpenODF(filename)
    @headers = {}
  
  getHeader: (name) =>
    @headers[name] = @headers[name] or OdfHeader(@file,name)
    return @headers[name]
  
  getInt: (header,...) =>
    @getHeader(header)\getInt(...)

  getFloat: (header,...) =>
    @getHeader(header)\getFloat(...)

  getProperty: (header,...) =>
    @getHeader(header)\getProperty(...)

  getBool: (header,...) =>
    @getHeader(header)\getBool(...)

  getTable: (header,...) =>
    @getHeader(header)\getTable(...)

  getVector: (header,...) =>
    @getHeader(header)\getVector(...)


--Other functions
normalWeapons = {"cannon","machinegun","thermallauncher","imagelauncher"}
dispenserWeps = {
  radarlauncher: {"RadarLauncherClass", "objectClass"}, 
  dispenser: {"DispenserClass", "objectClass"}
}

getAmmoCost = (odf using nil) ->
  ofile = OdfFile(odf)
  classLabel = ofile\getProperty("WeaponClass","classLabel")
  if(isIn(classLabel,normalWeapons))
    ord = wepOdf\getProperty("WeaponClass","ordName")
    if(ord)
      ordFile = OdfFile(ord)
      return ordFile\getInt("OrdnanceClass","ammoCost")
  
  return 0

spawnInFormation = (formation,location,direction,unitlist,team,seperation) ->
  if seperation == nil
    seperation = 10

  ret = {}

  formationAlign = Normalize(SetVector(-direction.z,0,direction.x))
  directionVec = Normalize(SetVector(direction.x,0,direction.z))

  for i, v in ipairs(formation)
    length = v\len()
    i2 = 1
    for c in v\gmatch(".")
      n = tonumber(c)
      if n
        x = (i2 - length/2) * seperation
        z = i*seperation*2
        position = x*formationAlign - z*directionVec + location
        transform = BuildDirectionalMatrix(position,directionVec)
        table.insert(ret,BuildObject(unitlist[n],team,transform))

  return ret


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
      protectedCall(v,"load",unpack(data[i]))
  
  gameKey: (...) =>
    proxyCall(@submodules,"gameKey", ...)

  receive: (...) => 
    proxyCall(@submodules,"receive", ...)

  command: (...) =>
    proxyCall(@submodules,"command", ...) 

  useModule: (cls) =>
    inst = cls(@)
    @submodules[getFullName(cls)] = inst
    return inst





spawnInFormation2 = (formation, location, ...) ->
  spawnInFormation(formation, GetPosition(location, 0), GetPosition(location, 1) - GetPosition(location, 0), ...)


createClass = (name, methods, parent) ->
  _class = nil
  _class = {
    __init: (...) => 
      if methods.new
        methods.new(@,...)
      elseif _class.__parent
        _class.__parent.__init(@, ...)

    __base: _base,
    __name: name,
    __parent: parent,
    __inherited: methods.__inherited
  }
  _base = ommit(methods,{"new","super"}) or {}
  _base.__index = _base
  _base.super = (name,...) =>
    _class.__parent[name](@,...) 
  if parent
    setmetatable(_base, parent.__base)

  _class = setmetatable(_class, {
    __index: (name) =>
      val = rawget(_base, name)
      if val == nil then
        _parent = rawget(@, "__parent")
        if _parent then
          return _parent[name]    
      else
        return val

    __call: (...) => 
      _self = setmetatable({}, _base)
      @.__init(_self, ...)
      return _self

  })
  _base.__class = _class
  if parent and parent.__inherited then
     parent.__inherited(parent, _class)

  return _class

namespace("utils", Module, Timer, Area)


{
  :proxyCall,
  :protectedCall,
  :str2vec,
  :stringlist,
  :local2Global,
  :global2Local,
  :getHash,
  :assignObject,
  :isIn,
  :getMeta,
  :applyMeta,
  :Timer,
  :Area,
  :OdfFile,
  :spawnInFormation,
  :spawnInFormation2,
  :namespace,
  :getFullName,
  :dropMeta,
  :createClass,
  :superCall,
  :superClass,
  :Module,
  :instanceof,
  :isNullPos,
  :Store
}