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
    let playerTitle = "PLAYER"
    let queueTitle = "PLAYLIST"
    
    override var currentFooterHeight: CGFloat { get { return 66 } }
    override var preferredPlaybackFooterHeight: CGFloat { get { return 66 } }
    
    // non-nil if the playlist is server-loaded
    var savedPlaylist: SavedPlaylist? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        playerNavbar()
        initUI()
    }
    
    func playerNavbar() {
        navigationItem.title = playerTitle
        navigationItem.leftBarButtonItems = []
        navigationItem.rightBarButtonItems = []
    }
    
    func queueNavbar() {
        navigationItem.title = queueTitle
        navigationItem.leftBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .bookmarks, target: self, action: #selector(loadPlaylistClicked(_:))),
            UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(dragClicked(_:)))
        ]
        // the first element in the array is right-most
        navigationItem.rightBarButtonItems = [
            UIBarButtonItem(barButtonSystemItem: .save, target: self, action: #selector(savePlaylistClicked(_:)))
        ]
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
//        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var childViewControllerForStatusBarStyle: UIViewController? { get { return current } }
    
    @objc func dragClicked(_ dragButton: UIBarButtonItem) {
        if let current = current as? PlayQueueController {
            current.dragClicked(dragButton)
        } else {
            log.warn("Cannot edit non-UITableViewController")
        }
    }

    @objc func loadPlaylistClicked(_ button: UIBarButtonItem) {
        if let current = current as? PlayQueueController {
            current.loadPlaylistClicked(button)
        } else {
            log.warn("Cannot load from non-UITableViewController")
        }
    }

    @objc func savePlaylistClicked(_ item: UIBarButtonItem) {
        if let current = current as? PlayQueueController {
            current.savePlaylistClicked(item)
        } else {
            log.warn("Cannot save from non-UITableViewController")
        }
    }
    
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
        navigationItem.title = playerTitle
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
            playerNavbar()
        case queueIndex:
            swap(oldVc: current, newVc: PlayQueueController(), options: .transitionFlipFromRight)
            queueNavbar()
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
        }
    }
}
