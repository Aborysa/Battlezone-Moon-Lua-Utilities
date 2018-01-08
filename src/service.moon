

rx = require("rx")

import AsyncSubject, Observable from rx

class ServiceManager
  new: () =>
    @services = {}
    @serviceRequests = {}

  createService: (name, service) =>
    if @services[name] ~= nil
      error("Service already registered")
    @services[name] = service
    if @serviceRequests[name] == nil
      @serviceRequests[name] = AsyncSubject.create()
    req = @serviceRequests[name]
    req\onNext(service)
    req\onCompleted()

  hasService: (name) =>
    @services[name] ~= nil

  getServiceSync: (name) =>
    return @services[name]

  getService: (name) =>
    if @serviceRequests[name] == nil
      @serviceRequests[name] = AsyncSubject.create()

    return @serviceRequests[name]

  getServices: (...) =>
    return Observable.zip(unpack([@getService(name) for name in *{...}]))

  getServicesSync: (...) =>
    return unpack([@getServicesSync(name) for name in *{...}])

return {
  :ServiceManager
}