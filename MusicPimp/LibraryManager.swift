import Foundation

class LibraryManager: EndpointManager {
  let log = LoggerFactory.shared.pimp(LibraryManager.self)
  static let sharedInstance = LibraryManager()

  @Published var libraryUpdated: LibraryType

  init() {
    log.info("Init library manager")
    let settings = PimpSettings.sharedInstance
    libraryUpdated = Libraries.fromEndpoint(settings.activeEndpoint(PimpSettings.LIBRARY))
    super.init(key: PimpSettings.LIBRARY, settings: settings)
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
