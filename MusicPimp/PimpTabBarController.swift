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
    
    override func viewDidLoad() {
        let tabs = tabBar.items
        if let tabs = tabs {
            decorate(tabs[0], title: "Music", fontAwesomeName: "music")
            decorate(tabs[1], title: "Player", fontAwesomeName: "play-circle")
            decorate(tabs[2], title: "Playlist", fontAwesomeName: "list")
            decorate(tabs[3], title: "Settings", fontAwesomeName: "wrench")
        }
//        self.tabBar.backgroundColor = PimpColors.background
//        tabBar.barTintColor = PimpColors.background
    }
    
    func decorate(tabItem: UITabBarItem, title: String, fontAwesomeName: String) {
        tabItem.title = title
        let (selected, notSelected) = iconPair("fa-\(fontAwesomeName)")
        tabItem.image = notSelected
        tabItem.selectedImage = selected
    }
    
    func iconPair(name: String) -> (UIImage, UIImage) {
        let selected = icon(name, selected: true)
        let notSelected = icon(name, selected: false)
        return (selected, notSelected)
    }
    
    func icon(name: String, selected: Bool) -> UIImage {
        let iconColor = selected ? PimpColors.tintColor : UIColor.grayColor()
        let image = UIImage(icon: name, backgroundColor: UIColor.clearColor(), iconColor: iconColor, fontSize: tabIconFontSize)
        return image.imageWithRenderingMode(UIImageRenderingMode.AlwaysOriginal)
    }

}
