//
//  ContainerParent.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 13/08/16.
//  Copyright © 2016 Skogberg Labs. All rights reserved.
//

import Foundation
import SnapKit

class ContainerParent: ListeningController, PlaybackDelegate {
    let playbackFooter = SnapPlaybackFooter()
    let playbackFooterHeightValue: CGFloat = 44
    private var currentFooterHeight: CGFloat = 0
    
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
    
    func initChild(_ child: UIViewController) {
        addChildViewController(child)
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        child.didMove(toParentViewController: self)
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
            // hidden by default
            make.height.equalTo(currentFooterHeight)
        }
    }

    override func onStateChanged(_ state: PlaybackState) {
        self.view.setNeedsUpdateConstraints()
        let isVisible = state == .Playing
        Util.onUiThread {
            self.playbackFooter.updatePlayPause(isPlaying: isVisible)
        }
    }
    
    override func updateViewConstraints() {
        let footerHeight = player.current().state == .Playing ? playbackFooterHeightValue : 0
        if footerHeight != currentFooterHeight {
            self.playbackFooter.snp.updateConstraints { make in
                currentFooterHeight = make.height.equalTo(footerHeight).constraint.layoutConstraints[0].constant
            }
        }
        super.updateViewConstraints()
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
    
//    func findChild<T>() -> T? {
//        let pcs = childViewControllers.flatMapOpt { (vc) -> T? in
//            return vc as? T
//        }
//        return pcs.headOption()
//    }
}
