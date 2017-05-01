//
//  ContainerParent.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 13/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation

class ContainerParent: ListeningController, PlaybackDelegate {
    let playbackFooter = SnapPlaybackFooter()
    let playbackFooterHeightValue: CGFloat = 44
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initPlaybackFooter()
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
    
    func initPlaybackFooter() {
        view.addSubview(playbackFooter)
        playbackFooter.snp.makeConstraints { make in
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.trailing.equalTo(self.view.snp.trailingMargin)
            make.bottom.equalToSuperview()
            make.height.equalTo(playbackFooterHeightValue)
        }
    }

    override func onStateChanged(_ state: PlaybackState) {
        let isVisible = state == .Playing
        Util.onUiThread {
            self.playbackFooter.updatePlayPause(isPlaying: isVisible)
//            self.playbackFooter.isHidden = !isVisible
//            self.playbackFooterHeight.constant = isVisible ? self.playbackFooterHeightValue : 0
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
