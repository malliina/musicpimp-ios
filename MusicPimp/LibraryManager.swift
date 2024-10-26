import Foundation

class LibraryManager: EndpointManager {
  let log = LoggerFactory.shared.pimp(LibraryManager.self)
  static let sharedInstance = LibraryManager()

  @Published var libraryUpdated: LibraryType

  var latestUpdate: Date = Date.now
  
  
  init() {
    log.info("Init library manager")
    let settings = PimpSettings.sharedInstance
    libraryUpdated = Libraries.fromEndpoint(settings.activeEndpoint(PimpSettings.LIBRARY))
    super.init(key: PimpSettings.LIBRARY, settings: settings)
    let contentUpdates = $libraryUpdated.flatMap { lib in
      lib.contentsUpdatedPublisher
    }.map { c in Date.now }
    let _ = Task {
      for await updated in contentUpdates.values {
        latestUpdate = updated
      }
    }
  }

  func endpoints() -> [Endpoint] {
    settings.endpoints()
  }

  func use(endpoint: Endpoint) async -> LibraryType {
    let _ = saveActive(endpoint)
    libraryUpdated = Libraries.fromEndpoint(endpoint)
    log.info("Library set to \(endpoint.name)")
    return libraryUpdated
  }
}
