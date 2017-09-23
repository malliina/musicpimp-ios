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
    let playbackFooterHeightValue: CGFloat
    
    let playbackFooter = SnapPlaybackFooter()
    var currentFooterHeight: CGFloat { get { return 0 } }
    var preferredPlaybackFooterHeight: CGFloat { get { return player.current().state == .Playing ? playbackFooterHeightValue : 0 } }
    private var currentHeight: CGFloat = 0
    
    convenience init() {
        self.init(footerHeight: 44)
    }
    
    init(footerHeight: CGFloat) {
        self.playbackFooterHeightValue = footerHeight
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.playbackFooterHeightValue = 44
        super.init(coder: aDecoder)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initPlaybackFooter()
        self.automaticallyAdjustsScrollViewInsets = false
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateFooterState()
    }
    
//    https://developer.apple.com/library/content/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html#//apple_ref/doc/uid/TP40007457-CH11-SW12
    func initChild(_ child: UIViewController) {
        addChildViewController(child)
        // ?
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        child.didMove(toParentViewController: self)
    }
    
    fileprivate func updateFooterState() {
        onStateChanged(player.current().state)
    }
    
    func initPlaybackFooter() {
        playbackFooter.delegate = self
        view.addSubview(playbackFooter)
        playbackFooter.snp.makeConstraints { make in
            make.leading.equalTo(self.view.snp.leadingMargin)
            make.trailing.equalTo(self.view.snp.trailingMargin)
            make.bottom.equalToSuperview()
            // hidden by default
            make.height.equalTo(currentFooterHeight)
            currentHeight = currentFooterHeight
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
        let footerHeight = preferredPlaybackFooterHeight
        if footerHeight != currentHeight {
            currentHeight = footerHeight
            self.playbackFooter.snp.updateConstraints { make in
                make.height.equalTo(footerHeight)
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
}
