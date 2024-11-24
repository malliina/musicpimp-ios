import Foundation

class LibraryManager: EndpointManager, EndpointSource {
  let log = LoggerFactory.shared.pimp(LibraryManager.self)
  static let sharedInstance = LibraryManager()

  @Published var libraryUpdated: LibraryType

  var latestUpdate: Date = Date.now
  
  init() {
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
  
  func use(endpoint: Endpoint) async {
    let _ = saveActive(endpoint)
    libraryUpdated = Libraries.fromEndpoint(endpoint)
    log.info("Library set to \(endpoint.name)")
  }
  
  func endpoints() -> [Endpoint] {
    settings.endpoints()
  }
  
  func remove(id: String) async -> [Endpoint] {
    let active = loadActive()
    var es = settings.endpoints()
    if let idx = es.indexOf({$0.id == id}) {
      let removed = es.remove(at: idx)
      settings.saveAll(es)
      if active.id == removed.id {
        await use(endpoint: Endpoint.Local)
      }
    }
    return es
  }
}
