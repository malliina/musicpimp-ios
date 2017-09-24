//
//  TopFlipController.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 24/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class TopFlipController: FlipController {
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "PLAYLISTS"
    }
    
    override var firstTitle: String { return "Popular" }
    override var secondTitle: String { return "Recent" }
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
