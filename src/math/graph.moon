
utils = require("utils")

print(utils)
import simpleIdGeneratorFactory, applyMeta, getMeta from utils
idGenerator = simpleIdGeneratorFactory()


DijkstraSearch = nil
AstarSearch = nil

class Path
  new: (nodes, cost) =>
    @nodes = nodes
    @cost = cost

  getCost: () =>
    @cost
  
  getNodes: () =>
    @nodes


Node, Edge = nil, nil

AddPositionMeta = (node, vec) ->
  applyMeta(node, {
    position: vec
  })

GetPositionMeta = (node) ->
  return getMeta(node, "position")

class Graph
  new: (nodes={}) =>
    @nodes = nodes
    -- memoized paths
    @paths = {}
    @heurisitcsFunc = () -> 0
    
  findPath: (start, goal, algo=DijkstraSearch, cache=true) =>
    -- find the shortest path
    if cache and @paths[start\getId()] and @paths[start\getId()][goal\getId()]
      return @paths[start\getId()][goal\getId()]
    
    path = algo(start, goal, @nodes, @heurisitcsFunc)
    if not @paths[start\getId()]
      @paths[start\getId()] = {}

    if not @paths[goal\getId()]
      @paths[goal\getId()] = {}

    @paths[start\getId()][goal\getId()] = path
    @paths[goal\getId()][start\getId()] = Path(table.reverse(path\getNodes()), path\getCost())

    return path 

  addNodes: (nodes) =>
    for i, v in ipairs(nodes)
      table.insert(@nodes, v)

  setHeuristicsFunction: (func) =>
    @heurisitcsFunc = func

  getAllNodes: () =>
    @nodes
  
  clone: () =>
    nodes = {}
    edges = {}
    for i, v in ipairs(@nodes)
      node = v\clone()
      nodes[v\getId()] = node
      for j, edge in ipairs(v\getEdges())
        nedge = edge\clone()
        if not edges[nedge]
          edges[nedge] = {}
        
        connections = edge\getNodes()
        table.insert(edges[nedge], [n for _, n in ipairs(connections)])

    for i, v in ipairs(edges)
      n1 = nodes[v[1]]
      n2 = nodes[v[2]]
      i\connect(n1, n2)
    
    return Graph(nodes)

class Edge
  new: (weight) =>
    @weight = weight
    @connected = false
    @nodes = {}
    @id = idGenerator()

  connect: (n1, n2) =>
    if not @connected
      n1\addEdge(@)
      n2\addEdge(@)
      table.insert(@nodes, n1)
      table.insert(@nodes, n2)
      @connected = true

  getWeight: () =>
    @weight

  getNodes: () =>
    @nodes

  getId: () =>
    @id

  clone: () =>
    return Edge(@weight)

class Node
  new: (weight) =>
    @weight = weight
    @edges = {}
    @id = idGenerator()

  getWeight: () =>
    @weight

  addEdge: (edge) =>
    table.insert(@edges, edge)

  getEdges: () =>
    @edges

  setWeight: (weight) =>
    @weight = weight
  
  addWeight: (weight) =>
    @weight += weight

  getNeighbors: () =>
    nodes = {}
    for edge in *@edges
      enodes = edge\getNodes()
      for node in *enodes
        if node\getId() ~= @getId()
          nodes[node] = edge\getWeight() + node\getWeight()

    return nodes

  getId: () =>
    @id

  clone: () =>
    return Node(@weight)





DijkstraSearch = (start, goal, nodes) ->
  if start\getId() == goal\getId()
    return Path({start}, 0)
  visitedNodes = {}
  distances = {node, math.huge for node in *nodes}
  distances[start] = 0
  
  path = {}
  
  queue = {start}
  while #queue > 0
    mdist = math.huge
    currentNode = nil
    currentIndex = 1
    for i, node in ipairs(queue)
      if distances[node] < mdist
        mdist = distances[node]
        currentIndex = i
        
    currentNode = table.remove(queue, currentIndex)
    if currentNode == goal
      break

    for neighbor, cost in pairs(currentNode\getNeighbors())
      if not visitedNodes[neighbor]
        
        tcost = distances[currentNode] + cost 
        if tcost < distances[neighbor]
          distances[neighbor] = tcost
          path[neighbor] = currentNode
        
        table.insert(queue, neighbor)
    
    visitedNodes[currentNode] = true

  finalPath = {}
  u = goal
  
  if path[u]
    while u
      table.insert(finalPath, u)
      u = path[u]

  return Path(table.reverse(finalPath), distances[goal])

-- todo implement heurisitc cost estimate
AstarSearch = (start, goal, nodes, heurisitcsFunc) ->
  closedSet = {}
  openMap = {[start]: true}
  openSet = {start}
  path = {}

  gScore = {node, math.huge for node in *nodes}
  gScore[start] = 0

  fScore = {node, math.huge for node in *nodes}
  fScore[start] = heurisitcsFunc(start, goal)
  while #openSet > 0
    currentIndex = 1
    minf = math.huge
    for i, node in ipairs(openSet)
      if fScore[node] <= minf
        minf = fScore[node]
        currentIndex = i

    currentNode = table.remove(openSet, currentIndex)
    closedSet[currentNode] = true
    openMap[currentNode] = nil

-- TODO: FIX
    
    for neighbor, cost in pairs(currentNode\getNeighbors())
      if not closedSet[neighbor]
        tgScore = gScore[currentNode] + cost
        if not openMap[neighbor]
          openMap[neighbor] = true
          table.insert(openSet, neighbor)
        
        else if tgScore >= gScore[neighbor]
          continue
        
        path[neighbor] = currentNode
        gScore[neighbor] = tgScore
        fScore[neighbor] = gScore[neighbor] + heurisitcsFunc(neighbor, goal)


  finalPath = {}
  u = goal
  
  if path[u]
    while u
      table.insert(finalPath, u)
      u = path[u]

  return Path(table.reverse(finalPath), gScore[goal])

createDistanceHeuristics = (nodeMap) ->
  distanceMap = {}
  for node, pos in pairs(nodeMap)
    distanceMap[node] = {}
    for node2, pos2 in pairs(nodeMap)
      dist = Distance2D(pos, pos2)
      distanceMap[node][node2] = dist
    
  return (a, b) ->
    return distanceMap[a][b]


return {
  :Graph,
  :Node,
  :Edge,
  :DijkstraSearch,
  :AstarSearch,
  :createDistanceHeuristics,
  :AddPositionMeta,
  :GetPositionMeta
}