utils = require("utils")

import getFullName, getClass, getMeta, setMeta, applyMeta from utils


-- Default serializers used for components

-- use a serializer for a specific component class
useSerializer = (cls, serializer, include, exclude) ->
  setMeta(cls, "component_serializer", {
    serializer: serializer,
    include: include,
    exclude: exclude
  })


defaultKeyFunction = (object) ->
  ret = {}
  for key, value in pairs(object)
    startWithUnderscore = type(key) == "string" and key\find("_")
    if startWithUnderscore == nil or startWithUnderscore > 1
      ret[key] = value

  return ret





class Serializer
  @serialize: (component) =>
  @deserialize: (data, cls) =>
  @use: (cls, ...) =>
    useSerializer(cls, @@, ...)

class TinySerializer extends Serializer
  @serialize: (component) =>
    return defaultKeyFunction(component)

  @deserialize: (data, cls) =>
    return data

class BzTinyComponentSerializer
  @serialize: (component) =>
    className = getFullName(component)
    return defaultKeyFunction(component)

  @deserialize: (data, cls) =>
    component = cls()
    for k, v in pairs(data)
      component[k] = v
    
    return component


serializeEntity = (entity) ->
  ret = {}
  for name, component in pairs(entity)
    cls = component.__class
    serializer = TinySerializer
    clsName = nil
    if cls
      clsName = getFullName(cls)
      component_serializer = getMeta(cls).component_serializer
      if component_serializer
        serializer = getMeta(cls).component_serializer.serializer
      else
        serializer = BzTinyComponentSerializer
      
    componentData = serializer\serialize(component)

    ret[name] = {
      clsName: clsName,
      componentData: componentData
    }
  
  return ret

deserializeEntity = (entityData, entity) ->
  for componentName, data in pairs(entityData)
    serializer = TinySerializer
    entity[componentName] = {}
    cls = nil
    if data.clsName
      cls = getClass(data.clsName)
      component_serializer = getMeta(cls).component_serializer
      if component_serializer
        serializer = getMeta(cls).component_serializer.serializer
      else
        serializer = BzTinyComponentSerializer
      
    entity[componentName] = serializer\deserialize(data.componentData, cls)



return {
  :serializeEntity,
  :deserializeEntity,
  :Serializer,
  :TinySerializer,
  :BzTinyComponentSerializer,
  :defaultKeyFunction,
  :useSerializer
}
