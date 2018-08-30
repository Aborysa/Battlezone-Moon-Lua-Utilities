Rx = require("rx")

import Subject, ReplaySubject, AsyncSubject from Rx

--Consts
metadata = setmetatable({},{__mode: "k"})

--Util functions
_unpack = unpack
_GetOdf = GetOdf
_GetPilotClass  = GetPilotClass
_GetWeaponClass = GetWeaponClass
_OpenODF = OpenODF
_BuildObject = BuildObject


_odf_cache = setmetatable({},{__mode: "v"})

export OpenODF = (odf) ->
  _odf_cache[odf] = _odf_cache[odf]~=nil and _odf_cache[odf] or _OpenODF(odf)
  return _odf_cache[odf]

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
  IsTeamAllied(a, b) or a == b or a == 0 or b == 0


export IsBzr = () ->
  GameVersion\match("^2") ~= nil

export IsBz15 = () ->
  GameVersion\match("^1.5") ~= nil

export IsBz2 = () ->
  not (IsBzr or IsBz15)


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




userdataType = (userdata) ->
  meta = getmetatable(userdata)
  return meta.__type

sizeTable = {
  Handle: (handle) ->
    IsValid(handle) and 5 or 1
  ,
  nil: () -> 1
  ,
  boolean: () -> 1
  ,
  number: (num) ->
    if num == 0
      return 1
    if num/math.ceil(num) ~= 1
      return 9
    if num >= -128 and num <= 127
      return 2
    if num >= -32768 and num <= 32767
      return 3
    return 5
  ,
  string: (string) ->
    len = string\len()
    if len >= 31
      return 2 + len
    return 1 + len
  ,
  table: (tbl) ->
    count = 0
    for i, v in pairs(tbl)
      count = count + 1
    if count >= 31
      return 2 + 31
    return 1 + 31
  ,
  VECTOR_3D: (vec) ->
    return 13
  ,
  MAT_3D: (mat) ->
    return 12
  ,
  userdata: (data) ->
    return 13
}

sizeof = (a) ->
  t = type(a)
  if t == "userdata"
    t = userdataType(a)
  size = sizeTable[t](a)
  if t == "table"
    for key, value in pairs(a)
      size = size + sizeof(key) + sizeof(value)

  return size




isIn = (element, list) ->
  for e in *list
    if e == element
      return true
  return false

assignObject = (...) ->
  return {k,v for obj in *{...} for k, v in pairs(obj) }

copyList = (t, filter=()->true) ->
  return [v for i, v in ipairs(t) when filter(i,v)]

ommit = (table, fields) ->
  {k, v for k, v in pairs(table) when not isIn(k,fields)}


compareTables = (a, b) ->
  {k, v for k, v in pairs(assignObject(a,b)) when a[k] ~= b[k]  }


isNullPos = (pos) ->
  return pos.x == pos.y and pos.y == pos.z and pos.z == 0

getMeta = (obj, key) ->
  if key
    return {k,v for k,v in pairs( (metadata[obj] or {})[key] or {})}
  return {k,v for k,v in pairs(metadata[obj] or {})}

dropMeta = (obj, key) ->
  if key and metadata[obj]
    metadata[obj][key] = nil
  else
    metadata[obj] = nil


applyMeta = (obj,...) ->
  metadata[obj] = assignObject(getMeta(obj),...)

setMeta = (obj, key, value) ->
  m = getMeta(obj)
  m[key] = value
  applyMeta(obj, m)

namespace = (name,...) ->
  for i,v in pairs({...})
    applyMeta(v,{
      namespace: name
    })
  return ...

getFullName = (cls) ->
  if cls.__name
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

local2Global = (v,t) ->
  up = SetVector(t.up_x, t.up_y, t.up_z)
  front = SetVector(t.front_x, t.front_y, t.front_z)
  right = SetVector(t.right_x, t.right_y, t.right_z)
  return v.x * front + v.y * up + v.z * right

safeDiv = (a,b) ->
  if a == 0
    return 0
  if b == 0
    return math.hugh
  return a/b

safeDivV = (v1,v2) ->
  return SetVector(safeDiv(v1.x,v2.x), safeDiv(v1.y,v2.y), safeDiv(v1.z, v2.z))

global2Local = (v,t) ->
  up = SetVector(t.up_x, t.up_y, t.up_z)
  front = SetVector(t.front_x, t.front_y, t.front_z)
  right = SetVector(t.right_x, t.right_y, t.right_z)

  return SetVector(DotProduct(v, front), DotProduct(v, up), DotProduct(v, right))



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
    @updateSubject = Subject.create()
    @keyUpdateSubject = Subject.create()

  set: (key, value) =>
    @assign({[key]: value})

  delete: (...) =>
    p_state = @state
    @state = assignObject({}, @state)
    for i, v in ipairs({...})
      @state[v] = nil
      @keyUpdateSubject\onNext(v, nil)
    @updateSubject\onNext(@state, p_state)

  assign: (kv_pairs) =>
    p_state = @state
    @state = assignObject(@state, kv_pairs)
    for k, v in pairs(compareTables(p_state, @state))
      @keyUpdateSubject\onNext(k,v)
    @updateSubject\onNext(@state, p_state)

  silentSet: (key, value) =>
    @silentAssign({[key]: value})

  silentAssign: (kv_pairs) =>
    p_state = @state
    @state = assignObject(@state, kv_pairs)

  silentDelete: (...) =>
    @state = assignObject({}, @state)
    for i, v in ipairs({...})
      @state[v] = nil

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

  getValueAs: (parser, ...) =>
    return parser(@getProperty(...) or "")

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

  getTableOf: (parser, var, ...) =>
    t = @getTable(var, ...)
    return [parser(v) for i, v in ipairs(t)]

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

  getValueAs: (parser, header, ...) =>
    @getHeader(header)\getValueAs(parser, ...)

  getTableOf: (parser, header, ...) =>
    @getHeader(header)\getTableOf(parser, ...)


--Other functions
normalWeapons = {"cannon","machinegun","thermallauncher","imagelauncher", "snipergun"}
dispenserWeps = {
  radarlauncher: {"RadarLauncherClass", "objectClass"},
  dispenser: {"DispenserClass", "objectClass"}
}



getWepOrdnance = (odf using nil) ->
  ofile = OdfFile(odf)
  classLabel = ofile\getProperty("WeaponClass","classLabel")
  if(isIn(classLabel,normalWeapons)) or classLabel == "beamgun"
    ord = ofile\getProperty("WeaponClass","ordName")
    return ord


getWepAmmoCost = (odf using nil) ->
  ord = getWepOrdnance(odf)
  if ord
    ordFile = OdfFile(ord)
    return ordFile\getInt("OrdnanceClass","ammoCost")
  return 0

-- base damage only, no explosion
getWepDamage = (odf using nil) ->
  ord = getWepOrdnance(odf)
  if ord
    ordFile = OdfFile(ord)
    return ordFile\getInt("OrdnanceClass","damageBallistic") +
      ordFile\getInt("OrdnanceClass","damageConcussion") +
      ordFile\getInt("OrdnanceClass","damageFlame") +
      ordFile\getInt("OrdnanceClass","damageImpact")

  return 0

getWepDelay = (odf using nil) ->
  f = OdfFile(odf)
  wepc = f\getProperty("WeaponClass", "classLabel")
  if isIn(wepc, normalWeapons)
    d1 = f\getFloat("LauncherClass", "shotDelay", 0)
    return d1 > 0 and d1 or f\getFloat("CannonClass", "shotDelay", 0)
  elseif wepc == "beamgun"
    return 1

  return 0

dps_cache = {}

getWepDps = (odf using dps_cache) ->
  if dps_cache[odf]
    return dps_cache[odf]
  damage = getWepDamage(odf)
  delay = getWepDelay(odf)
  dps = 0
  if delay > 0
    dps = damage/delay

  dps_cache[odf] = dps
  return dps

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



spawnInFormation2 = (formation, location, ...) ->
  spawnInFormation(formation, GetPosition(location, 0), GetPosition(location, 1) - GetPosition(location, 0), ...)


createClass = (name, methods, parent) ->
  _class = nil
  _base = ommit(methods,{"new","super"}) or {}
  _base.__index = _base
  if parent
    setmetatable(_base, parent.__base)

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
  _base.super = (name,...) =>
    _class.__parent[name](@,...)


  _class = setmetatable(_class, {
    __index: (name) =>
      print("Indexing",name)
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

namespace("utils", Timer, Area)

_switchMap = (obs, func) ->
  return Observable.create((observer) ->
    obs\subscribe(
      (...) ->
        n = func(...)
        n\subscribe( (...) ->
          observer\onNext(...)
        )
    )
  )


{
  :proxyCall,
  :protectedCall,
  :str2vec,
  :stringlist,
  :global2Local,
  :local2Global,
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
  :instanceof,
  :isNullPos,
  :Store,
  :getWepDps,
  :compareTables,
  :copyList,
  :setMeta,
  :userdataType,
  :sizeof,
  :sizeTable
}
