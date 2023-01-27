import Foundation

class SideBySideTopList: ContainerParent {
    let popular = MostPopularList()
    let recent = MostRecentList()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        popular.showHeader = true
        recent.showHeader = true
        snapSideBySide()
        navigationItem.title = "PLAYLISTS"
    }
    
    func snapSideBySide() {
        initChild(popular)
        initChild(recent)
        // side-by-side, equal width
        popular.view.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.topMargin)
            make.bottom.equalTo(playbackFooter.snp.top)
            make.leading.equalTo(view)
            make.trailing.equalTo(recent.view.snp.leading)
            make.width.equalTo(recent.view)
        }
        recent.view.snp.makeConstraints { (make) in
            make.top.equalTo(view.snp.topMargin)
            make.bottom.equalTo(playbackFooter.snp.top)
            make.trailing.equalTo(view)
            make.leading.equalTo(popular.view.snp.trailing)
        }
    }
}
