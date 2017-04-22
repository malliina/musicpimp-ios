//
//  ContainerParent.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 13/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class ContainerParent: ListeningController, PlaybackDelegate {
    let playbackFooterHeightValue: CGFloat = 44
    
    @IBOutlet var playbackFooter: PlaybackFooter!
    @IBOutlet var playbackFooterHeight: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playbackFooter.delegate = self
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        initFooter()
    }
    
    fileprivate func initFooter() {
        onStateChanged(player.current().state)
    }

    override func onStateChanged(_ state: PlaybackState) {
        let isVisible = state == .Playing
        Util.onUiThread {
            self.playbackFooter.updatePlayPause(isPlaying: isVisible)
            self.playbackFooter.isHidden = !isVisible
            self.playbackFooterHeight.constant = isVisible ? self.playbackFooterHeightValue : 0
        }
    }
    
    func onPrev() {
        _ = player.prev()
    }
    
    func onPlayPause() {
        self.playOrPause()
    }
    
    func onNext() {
        _ = player.next()
    }
    
    fileprivate func playOrPause() {
        if player.current().isPlaying {
            _ = self.player.pause()
        } else {
            _ = limitChecked {
                self.player.play()
            }
        }
    }
    
    func findChild<T>() -> T? {
        let pcs = childViewControllers.flatMapOpt { (vc) -> T? in
            return vc as? T
        }
        return pcs.headOption()
    }
}
