//
//  PimpTabBarController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 20/06/15.
//  Copyright (c) 2015 Skogberg Labs. All rights reserved.
//

import Foundation
import UIKit

class PimpTabBarController: UITabBarController {
    let tabIconFontSize: Int32 = 24
    let tabItemTitleVerticalOffset: CGFloat = -3
    
    override func viewDidLoad() {
        super.viewDidLoad()
        viewControllers = [
            attachTab(vc: LibraryContainer(), title: "Music", fontAwesomeName: "music"),
            attachTab(vc: PlayerParent(), title: "Player", fontAwesomeName: "play-circle"),
            attachTab(vc: PlaylistParent(), title: "Playlists", fontAwesomeName: "list"),
            attachTab(vc: SettingsController(), title: "Settings", fontAwesomeName: "cog")
        ].map { vc in UINavigationController(rootViewController: vc) }
    }

    func attachTab(vc: UIViewController, title: String, fontAwesomeName: String) -> UIViewController {
        let item = UITabBarItem()
        decorate(item, title: title, fontAwesomeName: fontAwesomeName)
        vc.tabBarItem = item
        return vc
    }
    
    func decorate(_ tabItem: UITabBarItem, title: String, fontAwesomeName: String) {
        tabItem.title = title
        tabItem.titlePositionAdjustment = UIOffset(horizontal: 0, vertical: tabItemTitleVerticalOffset)
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
        let iconColor = selected ? PimpColors.tintColor : UIColor.gray
        let image = UIImage(icon: name, backgroundColor: .clear, iconColor: iconColor, fontSize: tabIconFontSize)
        return image!.withRenderingMode(.alwaysOriginal)
    }
}
