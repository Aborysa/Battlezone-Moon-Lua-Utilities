

fullSetup = (bzutils) ->
  _Start = _G["Start"]
  _Update = _G["Update"]
  _AddObject = _G["AddObject"]
  _CreateObject = _G["CreateObject"]
  _DeleteObject = _G["DeleteObject"]
  _Receive = _G["Receive"]
  _Save = _G["Save"]
  _Load = _G["Load"]
  _Command = _G["Command"]
  _GameKey = _G["GameKey"]

  export Start = () ->
    bzutils\start()
    if _Start
      _Start()

  export Update = (dtime) ->
    bzutils\update(dtime)
    if _Update
      _Update(dtime)

  export AddObject = (handle) ->
    bzutils\addObject(handle)
    if _AddObject
      _AddObject(handle)

  export DeleteObject = (handle) ->
    bzutils\deleteObject(handle)
    if _DeleteObject
      _DeleteObject(handle)

  export CreateObject = (handle) ->
    bzutils\createObject(handle)
    if _CreateObject
      _CreateObject(handle)
    
  export Receive = (...) ->
    bzutils\recieve(...)
    if _Receive
      _Receive(...)
    
  export Save = (...) ->
    
    if _Save
      return bzutils\save(), _Save()
    
    return bzutils\save()

  export Load = (bzutils_d, ...) ->
    bzutils\load(bzutils_d)
    if _Load
      _Load(...)

  export Receive = (...) ->
    bzutils\receive(...)
    if _Receive
      _Receive(...)
  export Command = (...) ->
    bzutils\command(...)
    _h = false
    if _Command
      _h = _Command(...)
  
  export GameKey = (...) ->
    bzutils\gameKey(...)
    if _GameKey
      _GameKey(...)

return {
  :fullSetup,
}