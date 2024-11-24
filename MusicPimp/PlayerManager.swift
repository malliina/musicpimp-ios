import Foundation

class PlayerManager: EndpointManager, EndpointSource {
  static let playerLog = LoggerFactory.shared.pimp(PlayerManager.self)
  private var log: Logger { PlayerManager.playerLog }
  static let sharedInstance = PlayerManager()
  let players = Players.sharedInstance

  @Published var playerChanged: PlayerType

  init() {
    let settings = PimpSettings.sharedInstance
    playerChanged = players.fromEndpoint(settings.activePlayer())
    super.init(key: PimpSettings.PLAYER, settings: settings)
  }

  func use(endpoint: Endpoint) async {
    await use(endpoint: endpoint) { _ in () }
  }

  func use(endpoint: Endpoint, onOpen: @escaping (PlayerType) async -> Void) async {
    playerChanged.close()
    let _ = saveActive(endpoint)
    let p = players.fromEndpoint(endpoint)
    playerChanged = p
    log.info("Player set to \(endpoint.name)")
    // async
    _ = await playerChanged.open()
    onOpened(p)
    await onOpen(p)
  }

  func onOpened(_ player: PlayerType) {

  }

  func onError(_ error: Error) {
    log.error("Player error \(error)")
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
