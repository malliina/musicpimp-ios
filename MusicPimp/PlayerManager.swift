
import Foundation
import RxSwift

class PlayerManager: EndpointManager {
    static let playerLog = LoggerFactory.shared.pimp(PlayerManager.self)
    fileprivate var log: Logger { return PlayerManager.playerLog }
    static let sharedInstance = PlayerManager()
    let players = Players.sharedInstance
    
    fileprivate var activePlayer: PlayerType
    var active: PlayerType { get { return activePlayer } }
    private let playerSubject = PublishSubject<PlayerType>()
    var playerChanged: Observable<PlayerType> { return playerSubject }
    let bag = DisposeBag()
    
    init() {
        let settings = PimpSettings.sharedInstance
        activePlayer = players.fromEndpoint(settings.activePlayer())
        super.init(key: PimpSettings.PLAYER, settings: settings)
    }
    
    func use(endpoint: Endpoint) {
        use(endpoint: endpoint) { _ in () }
    }
    
    func use(endpoint: Endpoint, onOpen: @escaping (PlayerType) -> Void) {
        activePlayer.close()
        let _ = saveActive(endpoint)
        let p = players.fromEndpoint(endpoint)
        activePlayer = p
        log.info("Player set to \(endpoint.name)")
        // async
        activePlayer.open().subscribe { (event) in
            switch event {
            case .next(_): ()
            case .error(let err): self.onError(err)
            case .completed:
                self.onOpened(p)
                onOpen(p)
            }
        }.disposed(by: bag)
        playerSubject.onNext(p)
    }

    func onOpened(_ player: PlayerType) {
        
    }
    
    func onError(_ error: Error) {
        log.error("Player error \(error)")
    }
}
