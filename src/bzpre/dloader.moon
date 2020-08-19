

import Observable, AsyncSubject from require("rx")



initSuccess = false

protectedRequire = (mod) ->
  status, val = pcall(require, mod)
  if not status
    return false
  return val

asyncRequires = {}

initLoader = (mod_id=0, dll=false, dev_id=nil) ->
  if initSuccess
    return true
  package.cpath ..= ";.\\..\\..\\workshop\\content\\301650\\%s\\?.dll;.\\mods\\%s\\?.dll"\format(mod_id, mod_id)
  if dll
    package.cpath ..= ";./dll/?.dll"
    package.cpath ..= ";./testdll/?.dll"
  if dev_id
    package.cpath ..= ";./addon/#{dev_id}/?.dll"
  
  bzpre = protectedRequire("bzpre")
  if bzpre
    dllp1 = bzpre.fullpath(".\\..\\..\\workshop\\content\\301650\\#{mod_id}")
    dllp2 = bzpre.fullpath(".\\mods\\#{mod_id}")
    
    package.cpath ..= ";#{dllp1}\\?.dll;#{dllp2}\\?.dll"
    if dev_id
      dllp3 = bzpre.fullpath(".\\addon\\#{dev_id}")
      package.cpath ..= ";#{dllp3}\\?.dll"
      bzpre.addPath(dllp3)
    
    
    bzpre.addPath(dllp1)
    bzpre.addPath(dllp2)
    
    if dll
      bzpre.addPath("./dll")
      bzpre.addPath("./testdll")

    initSuccess = true

    for i, v in pairs(asyncRequires)
      v\onNext(require(i))
      v\onCompleted()

    asyncRequires = {}

    return true
  return false

requireDll = (name) ->
  if initSuccess
    return Observable.of(require(name))
  
  if not asyncRequires[name]
    asyncRequires[name] = AsyncSubject.create()
  
  return asyncRequires[name]

requireDlls = (...) ->
  return Observable.zip(unpack([requireDll(name) for name in *{...}]))


return {
  :initLoader,
  :requireDll,
  :requireDlls 
}