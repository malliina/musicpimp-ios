import Foundation

class PlayerParent: FlipController {
    private let log = LoggerFactory.shared.vc(PlayerParent.self)

    override var currentFooterHeight: CGFloat { get { return 66 } }
    override var preferredPlaybackFooterHeight: CGFloat { get { return 66 } }
    override var firstTitle: String { "Player" }
    override var secondTitle: String { "Playlist" }
    
    override func buildFirst() -> UIViewController {
        return PlayerController()
    }
    
    override func buildSecond() -> UIViewController {
        return PlayQueueController()
    }
    
    override func onSwapped(to: UIViewController) {
        navigationItem.title = to.navigationItem.title
        navigationItem.leftBarButtonItems = to.navigationItem.leftBarButtonItems
        navigationItem.rightBarButtonItems = to.navigationItem.rightBarButtonItems
    }
    
    override func initUI() {
        super.initUI()
        playbackFooter.setBigSize()
    }
}
