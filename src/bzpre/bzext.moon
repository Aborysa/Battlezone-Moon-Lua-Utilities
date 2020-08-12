
import requireDlls from require("dloader")
import isIn from require("utils")

bzpre = nil



requireDlls("bzpre")\subscribe((a) ->
  bzpre = a
)


producers = {
  "recycler",
  "factory",
  "armory",
  "constructionrig"
}



IsProducer = (h) ->
  return (IsCraft(h) and isIn(GetClassLabel(h), producers))
    
HCheck = (check) ->
  return (f) ->
    return (h, ...) ->
      if(check(h))
        return f(h, ...)

ValidCheck = HCheck(IsValid)
CraftCheck = HCheck(IsCraft)
ProducerCheck = HCheck(IsProducer)




_appinfo = nil


craftStates = {
  [0]: "UNDEPLOYED",
  [1]: "DEPLOYING",
  [2]: "DEPLOYED",
  [3]: "UNDEPLOYING",
  DEPLOYED: 2,
  DEPLOYING: 1,
  UNDEPLOYED: 0,
  UNDEPLOYING: 3
}


getAppInfo = (id="301650") ->
  if not _appinfo
    _appinfo = bzpre.getAppInfo(id)
  return _appinfo

getUserId = (id) -> 
  getAppInfo(id)\gmatch('"LastOwner"%s*"(%d+)"')()


-- producer specific functions
setBuildDoneTime = ValidCheck(ProducerCheck((...) -> bzpre.setBuildDoneTime(...)))
getBuildDoneTime = ValidCheck(ProducerCheck((...) -> bzpre.getBuildDoneTime(...)))
setBuildProgress = ValidCheck(ProducerCheck((...) -> bzpre.setBuildProgress(...)))
getBuildProgress = ValidCheck(ProducerCheck((...) -> bzpre.getBuildProgress(...)))
getBuildTime = ValidCheck(ProducerCheck((...) -> bzpre.getBuildTime(...)))
getBuildOdf = ValidCheck(ProducerCheck((...) -> bzpre.getBuildOdf(...)))

findPlan = (...) -> bzpre.findPlan(...)

getCurrentParam = ValidCheck(CraftCheck((...) -> bzpre.getCurrentParam(...)))

getCurrentWhere = ValidCheck(CraftCheck((...) -> 

  ptr, x, z = bzpre.getCurrentWhere(...)
  print(ptr, x, z)
  vec = SetVector(x, 0, z)
  y = GetTerrainHeightAndNormal(vec)
  vec.y = y
  return vec
))



getCraftState = ValidCheck(CraftCheck((...) -> bzpre.getCraftState(...)))
setCraftState = ValidCheck(CraftCheck((...) -> bzpre.setCraftState(...)))


setAsUser = ValidCheck(CraftCheck((...) -> bzpre.setAsUser(...)))
getPitchAngle = ValidCheck(CraftCheck((...) -> bzpre.getPitchAngle(...)))

getScorePlayer = (...) -> bzpre.getScorePlayer(...)



writeString = (...) -> bzpre.writeString(...)
readString = (...) -> bzpre.readString(...)

return {
  :readString,
  :writeString,
  :getUserId,
  :getAppInfo,
  :setAsUser,
  :getPitchAngle,
  :getBuildDoneTime,
  :setBuildDoneTime,
  :getCurrentParam,
  :getCurrentWhere,
  :setBuildProgress,
  :getBuildProgress,
  :getBuildOdf,
  :getBuildTime,
  :getCraftState,
  :setCraftState,
  :craftStates,
  :getScorePlayer,
  :findPlan
}
