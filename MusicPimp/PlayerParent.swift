//
//  PlayerParent.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class PlayerParent: FlipController {
    private let log = LoggerFactory.vc("PlayerParent")

    override var currentFooterHeight: CGFloat { get { return 66 } }
    override var preferredPlaybackFooterHeight: CGFloat { get { return 66 } }
    override var firstTitle: String { return "Player" }
    override var secondTitle: String { return "Playlist" }
    
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
        playbackFooter.setSizes(prev: 24, playPause: 32, next: 24)
    }
}
