





initSuccess = false

protectedRequire = (mod) ->
  status, val = pcall(require, mod)
  if not status
    return false
  return val



initLoader = (mod_id=0, dll=false, addon=false) ->
  if initSuccess
    return true
  package.cpath ..= ";.\\..\\..\\workshop\\content\\301650\\%s\\?.dll;.\\mods\\%s\\?.dll"\format(mod_id, mod_id)
  if dll
    package.cpath ..= ";./dll/?.dll"
  if addon
    package.cpath ..= ";./testdll/?.dll"

  bzpre = protectedRequire("bzpre")
  if bzpre
    dllp1 = bzpre.fullpath(".\\..\\..\\workshop\\content\\301650\\#{mod_id}")
    dllp2 = bzpre.fullpath(".\\mods\\#{mod_id}")
    

    package.cpath ..= ";#{dllp1}\\?.dll;#{dllp2}\\?.dll"
  
    bzpre.addPath(dllp1)
    bzpre.addPath(dllp2)
    if dll
      bzpre.addPath("./dll")
    if addon
      bzpre.addPath("./testdll")
    
    bzext = protectedRequire("bzext")
    
    if bzext
      initSuccess = true
      return true
  return false




return {
  :initLoader
}