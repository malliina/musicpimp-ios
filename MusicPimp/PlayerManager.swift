import Foundation
import RxSwift

class PlayerManager: EndpointManager {
  static let playerLog = LoggerFactory.shared.pimp(PlayerManager.self)
  fileprivate var log: Logger { PlayerManager.playerLog }
  static let sharedInstance = PlayerManager()
  let players = Players.sharedInstance

  @Published var playerChanged: PlayerType
  let bag = DisposeBag()

  init() {
    let settings = PimpSettings.sharedInstance
    playerChanged = players.fromEndpoint(settings.activePlayer())
    super.init(key: PimpSettings.PLAYER, settings: settings)
  }

  func use(endpoint: Endpoint) {
    use(endpoint: endpoint) { _ in () }
  }

  func use(endpoint: Endpoint, onOpen: @escaping (PlayerType) -> Void) {
    playerChanged.close()
    let _ = saveActive(endpoint)
    let p = players.fromEndpoint(endpoint)
    playerChanged = p
    log.info("Player set to \(endpoint.name)")
    // async
    playerChanged.open().subscribe { (event) in
      switch event {
      case .next(_): ()
      case .error(let err): self.onError(err)
      case .completed:
        self.onOpened(p)
        onOpen(p)
      }
    }.disposed(by: bag)
  }

  func onOpened(_ player: PlayerType) {

  }

  func onError(_ error: Error) {
    log.error("Player error \(error)")
  }
}
