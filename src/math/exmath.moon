



max = math.max
min = math.min 

pointOnLine = (p, q, r) ->
  return (q.x <= max(p.x, r.x)) and (q.x >= min(p.x, r.x) ) and (q.z <= max(p.z, r.z)) and (q.z >= min(p.z, r.z))

vectorOrinetation = (p, q, r) ->
  val = ((q.z - p.z) * (r.x - q.x)) - ((q.x - p.x) * (r.z - q.z))

  if (val == 0) 
    return 0
  if (val > 0)
    return 1
  return 2


doVectorsIntersect = (p1, q1, p2, q2) ->
  o1 = vectorOrinetation(p1, q1, p2)
  o2 = vectorOrinetation(p1, q1, q2)
  o3 = vectorOrinetation(p2, q2, p1)
  o4 = vectorOrinetation(p2, q2, q1)
  
  if (o1 ~= o2 and o3 ~= o4) 
      return true

  if(o1 == 0 and pointOnLine(p1, p2, q1))
    return true

  if(o2 == 0 and pointOnLine(p1, q2, q1))
    return true

  if(o3 == 0 and pointOnLine(p2, p1, q2))
    return true

  if(o4 == 0 and pointOnLine(p2, p1, q2))
    return true

  return false

pointOfIntersection = (p1, p2, q1, q2) ->
  if doVectorsIntersect(p1, p2, q1, q2)
    v1 = p2 - p1
    v2 = q2 - q1
    a1 = (v1.z/v1.x)
    c1 = p1.z - a1*p1.x
    a2 = (v2.z/v2.x)
    c2 = q1.z - a2*q1.x

    if a1 >= math.huge and a2 >= math.huge
      return (p1 + q1 + p2 + q2) / 4
    
    if a1 >= math.huge
      return SetVector(p1.x, 0, a2*p1.x + c2)
    
    if a2 >= math.huge
      return SetVector(q1.x, 0, a1*q1.x + c1)
    
    x = (c2 - c1)/(a1 - a2)
    return SetVector(x, 0, a1*x + c1)

-- checks if two vector paths intersects
doVectorPathsIntersect = (p1, p2) ->
  if #p1 <= 0 or #p2 <= 0
    return false
  
  for i=2, #p1
    v1 = p1[i-1]
    v2 = p1[i]
    for j=2, #p2
      v3 = p2[j-1]
      v4 = p2[j]
      if doVectorsIntersect(v1, v2, v3, v4)
        return true
    
  return false

-- returns all the points of intersection between to vector paths
pointsOfPathIntersection = (p1, p2) ->
  if doVectorPathsIntersect(p1, p2)
    ret = {}
    for i=2, #p1
      v1 = p1[i-1]
      v2 = p1[i]
      for j=2, #p2
        v3 = p2[j-1]
        v4 = p2[j]
        intersection = pointOfIntersection(v1,v2,v3,v4)
        if intersection
          table.insert(ret, intersection)

    return ret

-- checks if a point is inside a vector path
getWindingNumber = (path, v1) ->
  intersections = pointsOfPathIntersection(path, {v1 , SetVector(math.huge, 0, v1.z)})
  if intersections
    return #intersections

  return 0

isInisdeVectorPath = (path, v1) ->
  return getWindingNumber(path, v1) % 2 ~= 0


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




class Area
  new: (routineFactory) =>
    @areaSubjects = {
      all: Subject.create()
    }
    @type = t
    @path = path
    @handles = {}
    @enabled = false
        --Calculate center and radius
    @_bounding()
    --register everyone that is inside
  
    -- create routine that keeps area updated
    if routineFactory
      @routineFactory = routineFactory
      @enable()

  enable: () =>
    if @_enabled
      return
    @_enabled = true
    for v in ObjectsInRange(@radius+50,@center)
      if IsInsideArea(@path,v)
        @handles[v] = true
    if @routineFactory
      @subscription = routineFactory()\subscribe(@\update)

  disable: () =>
    @_enabled = false
    if @subscription
      @subscription\unsubscribe()

  getPath: () =>
    @path

  getCenter: () =>
    @center

  getObjects: () =>
    return [i for i,v in pairs(@handles)]

  getRadius: () =>
    @radius

  _bounding: () =>
    error("Not implemented")


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

class PolyArea extends Area
  new: (...) =>
    super(...)

  _bounding: () =>
    center = GetCenterOfPath(@path)
    radius = 0
    for i,v in ipairs(GetPathPoints(@path)) do
      radius = math.max(radius,Length(v-center))

    @center = center
    @radius = radius


return {
  :pointOfIntersection,
  :doVectorsIntersect,
  :doVectorPathsIntersect,
  :pointsOfPathIntersection,
  :local2Global,
  :global2Local,
  :Area,
  :PolyArea
}


