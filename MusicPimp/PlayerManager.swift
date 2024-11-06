import Foundation

class PlayerManager: EndpointManager {
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
}
