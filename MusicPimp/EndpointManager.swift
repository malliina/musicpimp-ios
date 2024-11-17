import Foundation

protocol EndpointSource {
  var settings: PimpSettings { get }
  func endpoints() -> [Endpoint]
  func loadActive() -> Endpoint
  func use(endpoint: Endpoint) async
  func remove(id: String) async -> [Endpoint]
}

class EndpointManager {
  static let endpointLog = LoggerFactory.shared.system(EndpointManager.self)
  fileprivate var log: Logger { EndpointManager.endpointLog }
  let key: String
  let settings: PimpSettings
  @Published var changed: Endpoint?

  init(key: String, settings: PimpSettings) {
    self.key = key
    self.settings = settings
  }

  func saveActive(_ e: Endpoint) -> ErrorMessage? {
    let err = settings.activate(id: e.id, key: key)
    if let err = err {
      log.error("Failed to save \(e.name) as active to key \(key), error was \(err.message)")
    } else {
      changed = e
    }
    return err
  }

  func loadActive() -> Endpoint {
    if let id = settings.impl.loadString(key) {
      return settings.endpoints().find({ $0.id == id }) ?? Endpoint.Local
    }
    log.error("Unable to load endpoint with key \(key).")
    return Endpoint.Local
  }
}
