//
//  PlayerParent.swift
//  MusicPimp
//
//  Created by Michael Skogberg on 23/09/2017.
//  Copyright © 2017 Skogberg Labs. All rights reserved.
//

import Foundation

class PlayerParent: ContainerParent {
    private let log = LoggerFactory.vc("PlayerParent")
    let scopeSegment = UISegmentedControl(items: ["Player", "Playlist"])
    var current: UIViewController = PlayerController()
    let playerIndex = 0
    let queueIndex = 1
    
    override var currentFooterHeight: CGFloat { get { return 66 } }
    override var preferredPlaybackFooterHeight: CGFloat { get { return 66 } }
    
    // non-nil if the playlist is server-loaded
    var savedPlaylist: SavedPlaylist? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initUI()
        updateNavbar()
    }
    
    func updateNavbar() {
        navigationItem.title = current.navigationItem.title
        navigationItem.leftBarButtonItems = current.navigationItem.leftBarButtonItems
        navigationItem.rightBarButtonItems = current.navigationItem.rightBarButtonItems
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
//    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
//        log.info("transition to w \(size.width) h \(size.height)")
//        super.viewWillTransition(to: size, with: coordinator)
//    }
    
    func initUI() {
        initScope(scopeSegment)
        addSubviews(views: [scopeSegment])
        scopeSegment.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(8)
            make.height.equalTo(32)
        }
        initChild(current)
        snap(child: current)
        playbackFooter.setSizes(prev: 24, playPause: 32, next: 24)
    }
    
    func snap(child: UIViewController) {
        child.view.snp.makeConstraints { make in
            make.top.equalTo(scopeSegment.snp.bottom).offset(8)
            make.leading.trailing.equalTo(view)
            make.bottom.equalTo(playbackFooter.snp.top)
        }
    }
    
    fileprivate func initScope(_ ctrl: UISegmentedControl) {
        ctrl.selectedSegmentIndex = 0
        ctrl.addTarget(self, action: #selector(scopeChanged(_:)), for: .valueChanged)
        ctrl.setTitleTextAttributes([NSAttributedStringKey.foregroundColor: PimpColors.tintColor], for: .normal)
    }
    
    @objc func scopeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case playerIndex:
            swap(oldVc: current, newVc: PlayerController(), options: .transitionFlipFromLeft)
        case queueIndex:
            swap(oldVc: current, newVc: PlayQueueController(), options: .transitionFlipFromRight)
        default:
            log.error("Unknown player segment index, must be 0 or 1.")
        }
    }
    
    // https://developer.apple.com/library/content/featuredarticles/ViewControllerPGforiPhoneOS/ImplementingaContainerViewController.html
    func swap(oldVc: UIViewController, newVc: UIViewController, options: UIViewAnimationOptions) {
        oldVc.willMove(toParentViewController: nil)
        self.addChildViewController(newVc)
        self.transition(from: oldVc, to: newVc, duration: 0.25, options: options, animations: { self.snap(child: newVc) }) { _ in
            oldVc.removeFromParentViewController()
            newVc.didMove(toParentViewController: self)
            self.current = newVc
            self.updateNavbar()
        }
    }
}
