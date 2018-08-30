utils = require("utils")

import getFullName, getMeta, setMeta, applyMeta from utils


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


  @deserialize: (data, cls) =>



serializeEntity = (entity) ->
  ret = {}
  for name, component in pairs(entity)
    cls = component.__class
    serializer = TinySerializer

    if cls
      clsName = getFullName(cls)
      serializer = getMeta(cls).component_serializer.serializer or serializer

    componentData = serializer\serialize(component)

    ret[name] = {
      clsName: className,
      componentData: componentData
    }

--deserializeEntity: (entityData) ->



return {
  :serializeEntity,
  :deserializeEntity,
  :Serializer,
  :TinySerializer,
  :BzTinyComponentSerializer,
  :defaultKeyFunction,
  :useSerializer
}
