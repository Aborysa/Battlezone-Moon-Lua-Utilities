

rx = require("rx")

import AsyncSubject from rx

class ServiceManager
  new: () =>
    @serivces = {}
    @serviceRequests = {}

  createService: (name, service) =>
    if @services[name] ~= nil
      error("Service already registered")
    @serivces[name] = service
    req = @serviceRequests[name]
    if req
      req\onNext(service)
      req\onCompleted()

  hasService: (name) =>
    @serivces[name] ~= nil

  getServiceSync: (name) =>
    return @services[name]

  getService: (name) =>
    if @serviceRequests[name] == nil
      @serviceRequests[name] = AsyncSubject.create()
      
    return @serviceRequests[name]

  getServices: (...) =>
   return Observable.zip([@getService(name) for name in *{...}])

  getServicesSync: (...) =>
    return unpack([@getServicesSync(name) for name in *{...}])

return {
  :ServiceManager
}