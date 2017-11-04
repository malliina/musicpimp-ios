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
    private let log = LoggerFactory.vc("ContainerParent")
    static var isIpad: Bool {
        get {
            let traits = UIScreen.main.traitCollection
            return traits.horizontalSizeClass == .regular && traits.verticalSizeClass == .regular
        }
    }
    static var defaultFooterHeight: CGFloat { return ContainerParent.isIpad ? 66 : 44 }
    let playbackFooterHeightValue: CGFloat
    
    let playbackFooter = SnapPlaybackFooter()
    var currentFooterHeight: CGFloat { get { return 0 } }
    private var initialFooterConstraint: Constraint? = nil
    private var playingFooterConstraint: Constraint? = nil
    
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
        Util.onUiThread {
            // Uses delays so that the footer does not flicker between transient track changes
            let buttonDelay: Double = animated ? 0.1 : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + buttonDelay) {
                self.playbackFooter.updatePlayPause(isPlaying: self.player.current().state == .Playing)
            }
            let footerDelay: Double = animated ? 1.0 : 0
            if animated {
                DispatchQueue.main.asyncAfter(deadline: .now() + footerDelay) {
                    let isPermanent = state == self.player.current().state
                    if isPermanent {
                        self.view.setNeedsUpdateConstraints()
                        if animated {
                            UIView.animate(withDuration: 0.25) {
                                self.view.layoutIfNeeded()
                            }
                        }
                    }
                }
            } else {
                self.view.setNeedsUpdateConstraints()
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
