import Foundation
import UIKit
import RxSwift

class PimpTabBarController: UITabBarController {
    private let log = LoggerFactory.shared.vc(PimpTabBarController.self)
    let utils = TabUtils.shared
    
    let tabItemTitleVerticalOffset: CGFloat = -3
    
    let flippablePlayer: UIViewController = TabUtils.shared.attachTab(vc: PlayerParent(persistent: true), title: "Player", fontAwesomeName: "play-circle")
    let stackedPlayer: UIViewController = TabUtils.shared.attachTab(vc: SideBySidePlayer(persistent: true), title: "Player", fontAwesomeName: "play-circle")
    // most popular and recent
    let flippableTopList: UIViewController = TabUtils.shared.attachTab(vc: TopFlipController(persistent: false), title: "Playlists", fontAwesomeName: "list")
    let sideBySideTopList: UIViewController = TabUtils.shared.attachTab(vc: SideBySideTopList(persistent: false), title: "Playlists", fontAwesomeName: "list")
    
    let bag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let trait = UIScreen.main.traitCollection
        let topList = UINavigationController(rootViewController: topListFor(traits: trait))
        var permanentTabs = [
            UINavigationController(rootViewController: utils.attachTab(vc: LibraryContainer(), title: "Music", fontAwesomeName: "music")),
            UINavigationController(rootViewController: playerFor(traits: trait)),
            UINavigationController(rootViewController: utils.attachTab(vc: PlaybackContainer(title: "SETTINGS", child: SettingsController(), persistentFooter: false), title: "Settings", fontAwesomeName: "cog"))
        ]
        if !LibraryManager.sharedInstance.active.isLocal {
            permanentTabs.insert(topList, at: 2)
        }
        viewControllers = permanentTabs
        LibraryManager.sharedInstance.libraryUpdated.subscribe(onNext: { (library) in
            Util.onUiThread {
                guard var vcs = self.viewControllers else { return }
                if vcs.count == 4 && library.isLocal {
                    vcs.remove(at: 2)
                } else if vcs.count == 3 && !library.isLocal {
                    vcs.insert(topList, at: 2)
                }
                // https://stackoverflow.com/a/9908361
                self.setViewControllers(vcs, animated: true)
            }
        }, onError: nil, onCompleted: nil, onDisposed: nil).disposed(by: bag)
    }
    
    // swaps between mobile and tablet viewcontrollers, as necessary, called when orientation changes
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        if let vcs = viewControllers, vcs.count > 2 {
            if let playerNav = vcs[1] as? UINavigationController {
                playerNav.viewControllers = [ playerFor(traits: newCollection) ]
            }
            // Sets the top list VC according to screen size
            if !LibraryManager.sharedInstance.active.isLocal, let listNav = vcs[2] as? UINavigationController {
                listNav.viewControllers = [ topListFor(traits: newCollection) ]
                listNav.setNavigationBarHidden(newCollection.horizontalSizeClass == .regular, animated: true)
            }
        }
        super.willTransition(to: newCollection, with: coordinator)
    }
    
    func playerFor(traits: UITraitCollection) -> UIViewController {
        let isBig = traits.horizontalSizeClass == .regular && traits.verticalSizeClass == .regular
        return isBig ? stackedPlayer : flippablePlayer
    }
    
    func topListFor(traits: UITraitCollection) -> UIViewController {
        let isWide = traits.horizontalSizeClass == .regular
        return isWide ? sideBySideTopList : flippableTopList
    }
}

class TabUtils {
    static let shared = TabUtils()

    let tabIconFontSize: Int32 = 24
    
    func attachTab(vc: UIViewController, title: String, fontAwesomeName: String) -> UIViewController {
        let item = UITabBarItem()
        decorate(item, title: title, fontAwesomeName: fontAwesomeName)
        vc.tabBarItem = item
        return vc
    }
    
    func decorate(_ tabItem: UITabBarItem, title: String, fontAwesomeName: String) {
        tabItem.title = title
//        tabItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: tabItemTitleVerticalOffset)
        let (selected, notSelected) = iconPair("fa-\(fontAwesomeName)")
        tabItem.image = notSelected
        tabItem.selectedImage = selected
    }
    
    func iconPair(_ name: String) -> (UIImage, UIImage) {
        let selected = icon(name, selected: true)
        let notSelected = icon(name, selected: false)
        return (selected, notSelected)
    }
    
    func icon(_ name: String, selected: Bool) -> UIImage {
        let iconColor = selected ? PimpColors.shared.tintColor : UIColor.gray
        let image = UIImage(icon: name, backgroundColor: .clear, iconColor: iconColor, fontSize: tabIconFontSize)
        return image!.withRenderingMode(.alwaysOriginal)
    }
}
