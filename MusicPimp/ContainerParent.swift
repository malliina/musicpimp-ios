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
    static var isIpad: Bool { get { return UIScreen.main.traitCollection.horizontalSizeClass == .regular && UIScreen.main.traitCollection.verticalSizeClass == .regular } }
    static var defaultFooterHeight: CGFloat { return ContainerParent.isIpad ? 66 : 44 }
    let playbackFooterHeightValue: CGFloat
    
    let playbackFooter = SnapPlaybackFooter()
    var currentFooterHeight: CGFloat { get { return 0 } }
    
    var preferredPlaybackFooterHeight: CGFloat {
        get {
            let state = player.current().state
            return state == .Playing || (ContainerParent.isIpad && state != .NoMedia) ? playbackFooterHeightValue : 0
        }
    }
    private var currentHeight: CGFloat = 0
    
    convenience init() {
        self.init(footerHeight: ContainerParent.defaultFooterHeight)
    }
    
    init(footerHeight: CGFloat) {
        self.playbackFooterHeightValue = footerHeight
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        self.playbackFooterHeightValue = ContainerParent.defaultFooterHeight
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
    
    /// https://developer.apple.com/library/content/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html#//apple_ref/doc/uid/TP40007457-CH11-SW12
    func initChild(_ child: UIViewController) {
        addChildViewController(child)
        // ?
        child.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(child.view)
        child.didMove(toParentViewController: self)
    }
    
    func initPlaybackFooter() {
        playbackFooter.delegate = self
        view.addSubview(playbackFooter)
        playbackFooter.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            // hidden by default
            make.height.equalTo(currentFooterHeight)
            currentHeight = currentFooterHeight
        }
    }
    
    fileprivate func updateFooterState() {
        updateFooter(state: player.current().state, animated: false)
    }

    override func onStateChanged(_ state: PlaybackState) {
        updateFooter(state: state, animated: true)
    }
    
    func updateFooter(state: PlaybackState, animated: Bool) {
        let isVisible = state == .Playing
        Util.onUiThread {
            self.view.setNeedsUpdateConstraints()
            self.playbackFooter.updatePlayPause(isPlaying: isVisible)
            // transitions the footer between visible and hidden states depending on whether music is playing
            if animated {
                // delays hiding so that it does not flicker between changing tracks, instead remains visible throughout
                let delay: TimeInterval = isVisible ? 0 : 2
                UIView.animate(withDuration: 0.25, delay: delay, options: .curveEaseInOut, animations: {
                    self.view.layoutIfNeeded()
                }, completion: nil)
            }
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
