import Foundation

class TopFlipController: FlipController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "PLAYLISTS"
    }
    
    override var firstTitle: String { "Popular" }
    override var secondTitle: String { "Recent" }
    override func buildFirst() -> UIViewController {
        let list = MostPopularList()
        list.showHeader = false
        return list
    }
    
    override func buildSecond() -> UIViewController {
        let list = MostRecentList()
        list.showHeader = false
        return list
    }
}
