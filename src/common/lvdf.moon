json = require("json")



default_file = "bundle.pvdf"



class VdfPart
  new: (name, pos, relpos) =>
    @name = name
    @pos = pos
    @relpos = relpos

  setParent: (parent) =>
    @parent = parent
  
  getName: () =>
    return @name

  getPosition: () =>
    return @pos

  getRelativePos: () =>
    return @relpos
  
  getParent: () =>
    return @parent

class VehicleDefinition
  new: (name) =>
    @name = name
    @parts = {}
    return

  getName: () =>
    return @name

  addPart: (shortname, part) =>
    @parts[shortname] = part 

  hasPart: (name) =>
    return @parts[name] ~= nil

  getPart: (name) =>
    if @hasPart(name)
      return @parts[name]

  getPartList: () =>
    return @parts


bundleCache = {}

loadBundle = (file=default_file) ->
  if bundleCache[file]
    return bundleCache[file]


  bundle = {}
  vdfs = json.decode(UseItem(file))
  for vdfName, struct in pairs(vdfs)
    vdf = VehicleDefinition(vdfName)
    for shortname, p in pairs(struct)
      part = VdfPart(p["fullname"], SetVector(unpack(p["pos"])), SetVector(unpack(p["relpos"])))
      part\setParent(p["parent"])
      vdf\addPart(shortname, part)

    for shortname, part in pairs(vdf\getPartList())
      parent = vdf\getPart(part\getParent())
      part\setParent(parent)
    
    bundle[vdfName] = vdf
  bundleCache[file] = bundle
  return bundle


return {
  :VdfPart,
  :VehicleDefinition,
  :loadBundle
}